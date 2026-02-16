return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- Setup treesitter for Neovim
    local treesitter = require("nvim-treesitter")
    treesitter.setup({
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
        "latex",
      },
      auto_install = true,
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
      autotag = { enable = true },
    })
  end,
}
