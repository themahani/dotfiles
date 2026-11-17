-- Copy to ~/.config/dotfiles/nvim.local.lua. All fields are optional.
-- schemas.lua supplies completion and validates keys/types when Neovim starts.
---@type DotfilesNvimConfig
local config = {
  copilot = false,
  servers_extra = { "rust_analyzer" },
  formatters_extra = { "shfmt" },
  -- debuggers_extra = { "delve" }, -- set its adapter and configurations in nvim.extra.lua
  -- Replace the entire language-server list:
  -- servers = { "lua_ls", "pyright", "ts_ls" },
  -- formatters = {}, -- disable automatic formatter installation
  -- debuggers = {}, -- disable automatic debug adapter installation
}
return config
