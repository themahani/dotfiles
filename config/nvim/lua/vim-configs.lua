-- # Map the leader keybinding to <space>
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- # Set tab options for the Python standard
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.breakindent = true -- Enable break indent

-- # Setup line numbers
vim.opt.nu = true -- Show line numbers by default
vim.opt.relativenumber = true -- Show relative line numbers

-- # Configs for vim backups
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true -- Save the undo history :)

-- # Configs for search
vim.opt.hlsearch = true -- Highlight search
vim.opt.incsearch = true -- Incremental search
vim.opt.inccommand = "split" -- Preview substitutions live
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.keymap.set("n", "'", "<cmd>nohlsearch<CR>") -- Set keymap to remove hightlights

-- # Configs for  nvim colors
vim.opt.termguicolors = true

-- # Configs for new splits
vim.opt.splitright = true -- New vertical split to right
vim.opt.splitbelow = true -- New horizontal split to below

-- # Faster window movement in nvim
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- # Configs for Yank
-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("nvim-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({
      opts = {
        higroup = "Visual",
        timeout = 300, -- Set the timeout of the highlight
      },
    })
  end,
})

-- # Misc
vim.opt.scrolloff = 4 -- Number of screen lines to keep above/below cursor
vim.opt.signcolumn = "yes" -- Keep the sign column on by default
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50 -- Faster update rate for neovim
vim.g.have_nerd_font = true -- Tell nvim that you have nerd fonts enabled.
vim.opt.wrap = false -- Disable line wrap
vim.opt.mouse = "a" -- Enable mouse mode. Can help with resizing splits
vim.opt.showmode = false -- Don't show the mode, since it's already in the status line
-- vim.opt.clipboard = "unnamedplus" -- Sync clipboard between OS and Nvim
vim.opt.timeoutlen = 800 -- Set mapped sequence wait time in milliseconds
vim.opt.cursorline = true -- Show which line your cursor is on

vim.keymap.set("n", ";", ":") -- Map ; to : for easier access to vim cmd
