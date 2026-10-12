-- Copy to ~/.config/dotfiles/nvim.extra.lua.
-- Executes after the repository's lazy.nvim setup; use Neovim's Lua API here.
-- Language servers, formatter install lists, and Copilot belong in nvim.local.lua.
vim.opt.relativenumber = false
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer" })

-- Example filetype mapping for a formatter added through formatters_extra:
-- require("conform").formatters_by_ft.sh = { "shfmt" }
