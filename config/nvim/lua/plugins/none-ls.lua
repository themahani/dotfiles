return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                -- Lua
                null_ls.builtins.formatting.stylua,
                -- Javascript
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.diagnostics.eslint_d,
                -- Python
                null_ls.builtins.formatting.black,
                null_ls.builtins.formatting.isort,
                -- C/C++
                null_ls.builtins.formatting.sg,
                null_ls.builtins.diagnostics.sg
            },
        })

        vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
    end,
}
