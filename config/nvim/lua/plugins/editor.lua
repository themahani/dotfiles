-- Plugins to enhance the editor workflow
local editor_plugins = {
  "tpope/vim-commentary", --
  "tpope/vim-surround", -- Work better with surrounding pairs {(<>)}
  "tpope/vim-repeat", -- Enhance repeat <.> capabilities
  -- "jiangmiao/auto-pairs", -- Add automatic pairing {(<>)}
  "tpope/vim-sleuth", -- Auto shift tabsize and tab width
  { -- Auto pairs for neovim
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
}

return editor_plugins
