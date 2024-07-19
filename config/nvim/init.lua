vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth =4")

-- Map the leader keybinding to <space>
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)

-- Setup lazy.nvim
require("lazy").setup("plugins")

-- Setup telescope for fuzzy find file searches
local builtin = require("telescope.builtin")
vim.keymap.set('n', '<C-p>', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})

-- Setup treesitter for Neovim
local treesitter_config = require("nvim-treesitter.configs")
treesitter_config.setup({
    ensure_installed = {"lua", "javascript", "c", "python", "vimdoc"},
    sync_install = false,
    highlight = { enable = true },
    indent = { enable = true },
})

-- Setup Neotree
vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {})


-- Set the colorscheme for nvim
require("catppuccin").setup()
vim.cmd.colorscheme "catppuccin"
