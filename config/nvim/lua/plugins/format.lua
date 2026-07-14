return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  dependencies = { "mason-org/mason.nvim" }, -- Ensure mason is loaded
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      markdown = { "prettier" },
      java = { "java-language-server" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  },
  config = function(_, opts)
    local conform = require("conform")
    conform.setup(opts)

    -- Native Mason check to ensure formatters are installed
    local mr = require("mason-registry")
    local formatters = { "stylua", "black", "prettier" }

    for _, tool in ipairs(formatters) do
      local p = mr.get_package(tool)
      if not p:is_installed() then
        p:install()
      end
    end

    -- Manual format keybind
    vim.keymap.set("n", "<leader>fb", function()
      conform.format({
        lsp_format = "fallback",
        async = true,
      })
    end, { desc = "[F]ormat Current [B]uffer" })
  end,
}
