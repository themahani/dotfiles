return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- Current nvim-treesitter (Neovim >= 0.12) installs parsers separately.
    -- The old ensure_installed/highlight setup keys are ignored by this API.
    local treesitter = require("nvim-treesitter")
    treesitter.setup({})
    treesitter.install({
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
    })
    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
      group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true }),
      callback = function(event)
        -- Parsers install asynchronously; missing/unsupported ones are harmless.
        pcall(vim.treesitter.start, event.buf)
      end,
    })
  end,
}
