-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Load vim configs
require("vim-configs")
local has_ui2, ui2 = pcall(require, "vim._core.ui2")
if has_ui2 and type(ui2.enable) == "function" then
  ui2.enable({})
end

-- Setup lazy.nvim
require("lazy").setup("plugins")

-- Local Lua can add editor options, mappings, commands, and autocmds.
local configHome = vim.env.XDG_CONFIG_HOME
if not configHome or configHome == "" then
  configHome = vim.env.HOME .. "/.config"
end
local extra = configHome .. "/dotfiles/nvim.extra.lua"
if vim.fn.filereadable(extra) == 1 then
  local ok, err = pcall(dofile, extra)
  if not ok then
    vim.notify("Error in " .. extra .. ": " .. tostring(err), vim.log.levels.WARN)
  end
end
