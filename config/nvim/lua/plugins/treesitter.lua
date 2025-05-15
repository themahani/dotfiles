return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        -- Setup treesitter for Neovim
        local treesitter_config = require("nvim-treesitter.configs")
        treesitter_config.setup({
            ensure_installed = {
                "lua", "javascript",  "tsx",  "toml",
                "yaml", "json", "css", "html",
                "c", "python", "vimdoc"
            },
            auto_install = true,
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
            autotag = { enable = true },
        })
    end
}
