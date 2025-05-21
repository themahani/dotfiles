return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },

  config = function()
    local conform = require("conform")

    --NOTE:MANUALLY INSTALL FORMATTER VIA MASON! DONT MAKE MASON CONFIG MESSY (ALSO BREAKING UPDATES IS A THING !)
    conform.setup({
      formatters_by_ft = {
        javascript = { "biome" },
        typescript = { "biome" },
        javascriptreact = { "biome" },
        typescriptreact = { "biome" },
        svelte = { "biome" },
        css = { "biome" },
        html = { "biome" },
        json = { "biome" },
        yaml = { "biome" },
        markdown = { "biome" },
        graphql = { "biome" },
        liquid = { "biome" },
        lua = { "stylua" },
        python = { "black", "isort" },
      },
      format_on_save = {
        async = false,
        timeout_ms = 2000,
        lsp_fallback = true,
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>ff", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
      vim.cmd.write()
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
