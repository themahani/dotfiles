"""Compile configs and exercise override precedence without starting plugins/Hyprland."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
TEST_TMP = "/tmp/opencode" if os.access("/tmp/opencode", os.W_OK) else None


@unittest.skipUnless(shutil.which("nvim"), "Neovim is required for Lua validation")
class LuaTests(unittest.TestCase):
    def test_syntax_schemas_and_local_extensions(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles-lua-", dir=TEST_TMP) as temporary:
            home = Path(temporary)
            script = home / "test.lua"
            script.write_text(r'''
local root = assert(os.getenv("DOTFILES_TEST_ROOT"))
local home = assert(os.getenv("HOME"))
local settings = home .. "/.config/dotfiles/"
vim.fn.mkdir(settings, "p")
for _, directory in ipairs({ "config/nvim", "config/dotfiles", "examples" }) do
  for _, file in ipairs(vim.fn.glob(root .. "/" .. directory .. "/**/*.lua", false, true)) do
    assert(loadfile(file))
  end
end
assert(loadfile(root .. "/config/hypr/hyprland.lua"))
for _, name in ipairs({ "schemas.lua", "nvim.lua", "hypr.lua" }) do
  vim.fn.writefile(vim.fn.readfile(root .. "/config/dotfiles/" .. name), settings .. name)
end
local schema = dofile(settings .. "schemas.lua")
assert(schema.validate("nvim", {}))
assert(schema.validate("hypr", {}))
assert(schema.validate("nvim", { servers = {}, formatters_extra = { "shfmt" } }))
assert(schema.validate("hypr", { mouse = false, autostart = {}, keyboard_options = "" }))
assert(not schema.validate("nvim", { copliot = true }), "typo passed schema validation")
assert(not schema.validate("nvim", { copilot = "yes" }), "invalid boolean passed schema validation")
assert(not schema.validate("nvim", { servers = { [2] = "lua_ls" } }), "sparse list passed schema validation")
assert(not schema.validate("nvim", { formatters = { "" } }), "empty formatter name passed schema validation")
assert(not schema.validate("hypr", { mouse = true }), "invalid mouse toggle passed schema validation")
assert(not schema.validate("hypr", { mouse = { name = "test", sensitivity = 2 } }), "invalid sensitivity passed schema validation")
assert(not schema.validate("hypr", { mouse = { name = "test", mystery = true } }), "unknown mouse key passed schema validation")
assert(not schema.validate("hypr", { keyboard_layout = {} }), "invalid layout passed schema validation")
assert(not schema.validate("nvim", "a string"), "non-table settings passed schema validation")
package.path = root .. "/config/nvim/lua/?.lua;" .. package.path
local function editor_options()
  package.loaded["dotfiles-options"] = nil
  return require("dotfiles-options")
end
local base_editor = editor_options()
assert(base_editor.copilot == true, "base Copilot setting changed")
assert(vim.list_contains(base_editor.servers, "texlab"), "base language servers changed")
vim.fn.writefile({ 'return { copilot = false, servers = { "clangd" }, servers_extra = { "clangd", "lua_ls" } }' }, settings .. "nvim.local.lua")
local options = editor_options()
assert(options.copilot == false, "local editor settings did not win")
assert(#options.servers == 2 and options.servers[1] == "clangd" and options.servers[2] == "lua_ls", "server append or deduplication failed")
vim.fn.writefile({ 'return { servers = {}, formatters = {} }' }, settings .. "nvim.local.lua")
assert(#editor_options().servers == 0 and #editor_options().formatters == 0, "empty lists failed to disable tools")
local notices = {}
local notify = vim.notify
vim.notify = function(message) table.insert(notices, message) end
vim.fn.writefile({ 'return { copilot = false, server = { "clangd" } }' }, settings .. "nvim.local.lua")
assert(editor_options().copilot == true, "invalid custom table was partly applied")
assert(#notices == 1 and notices[1]:find("unknown setting: server", 1, true), "invalid setting warning missing")
vim.fn.writefile({ 'return { servers = { "clangd" } }' }, settings .. "nvim.local.lua")
assert(#editor_options().servers == 1, "local settings were not refreshed")
vim.notify = notify

-- Exercise LSP selection without loading plugins, installing tools, or enabling LSPs.
local configured, mason = {}, nil
local original_lsp_config = vim.lsp.config
vim.lsp.config = function(name, value) configured[name] = value end
package.loaded["blink.cmp"] = { get_lsp_capabilities = function() return { test_capability = true } end }
package.loaded["mason-lspconfig"] = { setup = function(value) mason = value end }
local lsp = assert(loadfile(root .. "/config/nvim/lua/plugins/lsp.lua"))()
lsp.config()
assert(configured.clangd.capabilities.test_capability, "LSP capabilities missing")
assert(configured.pyright == nil, "unselected server configured")
assert(#mason.ensure_installed == 1 and mason.ensure_installed[1] == "clangd", "wrong LSP install selection")
assert(#mason.automatic_enable == 1 and mason.automatic_enable[1] == "clangd", "unrelated installed LSPs may be enabled")
assert(mason.handlers == nil, "removed Mason handler API still used")
vim.lsp.config = original_lsp_config

local parsers = nil
package.loaded["nvim-treesitter"] = {
  setup = function(value) assert(value.ensure_installed == nil) end,
  install = function(value) parsers = value end,
}
local treesitter = assert(loadfile(root .. "/config/nvim/lua/plugins/treesitter.lua"))()
treesitter.config()
assert(vim.list_contains(parsers, "lua") and vim.list_contains(parsers, "python"), "parsers not installed via current API")

local function dummy()
  return setmetatable({}, {
    __index = function(table, key)
      local child = dummy()
      rawset(table, key, child)
      return child
    end,
    __call = function() return {} end,
  })
end
local function desktop()
  local capture = { commands = {}, devices = {}, monitors = {} }
  hl = dummy()
  hl.config = function(value) capture.config = value end
  hl.device = function(value) table.insert(capture.devices, value) end
  hl.monitor = function(value) table.insert(capture.monitors, value) end
  hl.on = function(_, callback) capture.start = callback end
  hl.exec_cmd = function(command) table.insert(capture.commands, command) end
  assert(loadfile(root .. "/config/hypr/hyprland.lua"))()
  capture.start()
  return capture
end
local baseline = desktop()
assert(baseline.config.input.kb_layout == "us,ir", "base keyboard settings changed")
assert(#baseline.devices == 1 and baseline.devices[1].sensitivity == -0.5, "base mouse settings changed")
assert(baseline.commands[#baseline.commands] == "Telegram", "base startup changed")
vim.fn.writefile({ 'return { autostart_extra = { "Telegram", "extra-command" } }' }, settings .. "hypr.local.lua")
local extended = desktop()
assert(#extended.commands == #baseline.commands + 1 and extended.commands[#extended.commands] == "extra-command", "startup append or deduplication failed")
vim.fn.writefile({ 'return { keyboard_layout = "de", mouse = false, terminal = "test-terminal", autostart = { "test-only" } }' }, settings .. "hypr.local.lua")
vim.fn.writefile({ 'hl.monitor({ output = "test-monitor" })' }, settings .. "monitors.lua")
local custom = desktop()
assert(custom.config.input.kb_layout == "de", "local keyboard override failed")
assert(#custom.devices == 0, "mouse=false failed to disable device config")
assert(#custom.commands == 1 and custom.commands[1] == "test-only", "local startup override failed")
assert(custom.monitors[#custom.monitors].output == "test-monitor", "external layout was not loaded")
vim.fn.writefile({ 'return { autostart = {} }' }, settings .. "hypr.local.lua")
assert(#desktop().commands == 0, "empty startup list failed to disable apps")

-- Dynamic workspaces: { id, monitor, windows } per workspace, active ones per monitor.
local dynamic = dofile(root .. "/config/hypr/dynamic-workspaces.lua")
local function run(spec, action)
  local monitors, list, dispatched = {}, {}, {}
  for name in pairs(spec.active) do
    monitors[name] = { name = name, focused = name == (spec.focused or "eDP-1") }
  end
  for _, entry in ipairs(spec.workspaces) do
    local workspace = { id = entry[1], monitor = monitors[entry[2]], windows = entry[3], special = false }
    table.insert(list, workspace)
    if spec.active[entry[2]] == entry[1] then monitors[entry[2]].active_workspace = workspace end
  end
  local focused = monitors[spec.focused or "eDP-1"]
  hl = {
    get_workspaces = function() return list end,
    get_monitor = function(name) return monitors[name] end,
    get_active_monitor = function() return focused end,
    get_active_window = function()
      local workspace = focused.active_workspace
      return workspace.windows > 0 and { workspace = workspace, monitor = focused } or nil
    end,
    dispatch = function(value) table.insert(dispatched, value) end,
    dsp = {
      focus = function(value) return { focus = value } end,
      window = { move = function(value) return { move = value } end },
    },
  }
  action()
  return dispatched
end
local function strip(laptop_active, last_windows)
  return {
    active = { ["eDP-1"] = laptop_active, ["DP-1"] = 2 },
    workspaces = { { 1, "eDP-1", 2 }, { 2, "DP-1", 1 }, { 3, "eDP-1", 1 }, { 5, "eDP-1", last_windows or 1 }, { 6, "DP-1", 1 } },
  }
end
local function focused_on(dispatched)
  assert(#dispatched == 1 and dispatched[1].focus, "expected one focus dispatch")
  return dispatched[1].focus.workspace
end
assert(focused_on(run(strip(3), dynamic.focus(1))) == "5", "next workspace skipped an ID gap wrongly")
assert(focused_on(run(strip(5), dynamic.focus(1))) == "7", "trailing workspace took another monitor's ID")
assert(focused_on(run(strip(5), dynamic.focus_index(4))) == "7", "position past the end missed the trailing workspace")
assert(focused_on(run(strip(1), dynamic.focus_index(2))) == "3", "positions do not follow ID order")
assert(#run(strip(5), dynamic.focus_index(5)) == 0, "position beyond the trailing workspace dispatched")
assert(#run(strip(1), dynamic.focus(-1)) == 0, "previous from the first workspace wrapped")
assert(#run(strip(5, 0), dynamic.focus(1)) == 0, "next from the trailing empty workspace dispatched")
local other = run(strip(1), dynamic.focus(1, "DP-1"))
assert(#other == 2 and other[1].focus.monitor == "DP-1" and other[2].focus.workspace == "6", "bar on another monitor acted on the focused one")
assert(#run(strip(5), dynamic.move_window(1)) == 0, "moving the last workspace's only window renumbered it")
local moved = run(strip(5, 2), dynamic.move_window(1))
assert(#moved == 1 and moved[1].move.workspace == "7" and moved[1].move.follow, "window did not follow into the trailing workspace")
assert(#run(strip(1), dynamic.move_window(-1)) == 0, "moving left of the first workspace wrapped")
print("Lua syntax, schemas, plugin setup, and base/local customization validated")
''')
            result = subprocess.run(
                ["nvim", "--headless", "-u", "NONE", "-i", "NONE", "-n", "-l", str(script)],
                env={**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
                     "XDG_STATE_HOME": str(home / ".local/state"), "XDG_DATA_HOME": str(home / ".local/share"),
                     "XDG_CACHE_HOME": str(home / ".cache"), "DOTFILES_TEST_ROOT": str(ROOT)},
                cwd=home, text=True, capture_output=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
