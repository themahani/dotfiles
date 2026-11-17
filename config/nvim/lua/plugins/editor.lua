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
  { -- Icons, also served to plugins that require nvim-web-devicons
    "nvim-mini/mini.icons",
    version = false,
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}

return editor_plugins
