-- Plugins to enhance the editor workflow
local editor_plugins = {
  "tpope/vim-surround", -- Work better with surrounding pairs {(<>)}
  "tpope/vim-repeat", -- Enhance repeat <.> capabilities
  "tpope/vim-sleuth", -- Auto shift tabsize and tab width
  { -- Auto pairs for neovim
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },
}

return editor_plugins
