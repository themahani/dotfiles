return {
	{ "tpope/vim-fugitive" },
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({})

			-- Key maps
			vim.keymap.set("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", {})
			vim.keymap.set("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<CR>", {})
		end,
	},
}
