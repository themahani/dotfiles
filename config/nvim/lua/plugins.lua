
 return {
    {
     -- add your plugins here
     { "catppuccin/nvim", name = "catppuccin", priority = 1000 }, -- colorscheme to use on nvim
     -- init.lua:
     {
         'nvim-telescope/telescope.nvim', tag = '0.1.8',
         dependencies = { 'nvim-lua/plenary.nvim' }
     },
     {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
     {
         "nvim-neo-tree/neo-tree.nvim",
         branch = "v3.x",
         dependencies = {
             "nvim-lua/plenary.nvim",
             "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
             "MunifTanjim/nui.nvim",
             -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
         }
     }},
  -- install = { colorscheme = { "habamax" } },
  -- -- automatically check for plugin updates
  -- checker = { enabled = true },
  }
