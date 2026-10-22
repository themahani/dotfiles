---@type DotfilesNvimConfig
local config = {
	copilot = true,
	servers = {
		"clangd",
		"pyright",
		"html",
		"cssls",
		"marksman",
		"texlab",
		"ts_ls",
		"lua_ls",
		"jdtls",
		"ltex_plus",
		"ruff",
	},
	formatters = { "stylua", "prettier" },
}
return config
