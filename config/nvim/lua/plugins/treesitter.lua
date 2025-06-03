return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- Setup treesitter for Neovim
    local treesitter_config = require("nvim-treesitter.configs")
    treesitter_config.setup({
      ensure_installed = {
        -- Vim / Neovim
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        -- Web Dev
        "javascript",
        "typescript",
        "tsx",
        "css",
        "html",
        -- Config files
        "toml",
        "yaml",
        "json",
        "jsonc",
        "gitignore",
        -- C/C++, Python
        "c",
        "cpp",
        "make",
        "python",
        -- Markdown
        "markdown",
        "markdown_inline",
        "dockerfile",
      },
      auto_install = true,
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
      autotag = { enable = true },
    })
  end,
}
