return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000, -- Load before other plugins so they pick up its highlights
  opts = {}, -- auto_integrations (on by default) themes every installed plugin it supports
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
