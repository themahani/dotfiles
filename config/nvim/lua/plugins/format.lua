return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },

  config = function()
    local conform = require 'conform'

    --NOTE:MANUALLY INSTALL FORMATTER VIA MASON! DONT MAKE MASON CONFIG MESSY (ALSO BREAKING UPDATES IS A THING !)
    conform.setup {
      formatters_by_ft = {
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescriptreact = { 'prettier' },
        svelte = { 'prettier' },
        css = { 'prettier' },
        html = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
        graphql = { 'prettier' },
        liquid = { 'prettier' },
        lua = { 'stylua' },
        python = { 'black' },
      },
      format_on_save = {
        async = true,
        timeout_ms = 1000,
        lsp_fallback = true,
      },
    }

    vim.keymap.set({ 'n', 'v' }, '<leader>ff', function()
      conform.format {
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      }
      vim.cmd.write()
    end, { desc = 'Format file or range (in visual mode)' })
  end,
}
