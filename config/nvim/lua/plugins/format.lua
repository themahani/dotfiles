return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>fb",
      function()
        require("conform").format({
          lsp_format = "fallback",
          async = true,
        })
      end,
      desc = "[F]ormat Current [B]uffer",
    },
  },
  dependencies = { "mason-org/mason.nvim" }, -- Ensure mason is loaded
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      markdown = { "prettier" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  },
  config = function(_, opts)
    local conform = require("conform")
    conform.setup(opts)

    -- Install missing formatters from the Mason registry
    local registry = require("mason-registry")
    local formatters = require("dotfiles-options").formatters or { "stylua", "ruff", "prettier" }
    registry.refresh(function()
      for _, name in ipairs(formatters) do
        if not registry.has_package(name) then
          vim.notify("Unknown Mason package for formatter: " .. name, vim.log.levels.WARN)
        elseif not registry.is_installed(name) then
          registry.get_package(name):install()
        end
      end
    end)
  end,
}
