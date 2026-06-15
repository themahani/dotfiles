-- LSP Configuration
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "mason-org/mason.nvim",
      config = true, -- Automatically runs require("mason").setup()
    },
    "mason-org/mason-lspconfig.nvim",
  },

  config = function()
    -- Get default capabilities from Neovim's built-in client
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Map out language servers and their specific configurations
    local servers = {
      clangd = {},
      pyright = {},
      html = {},
      cssls = {},
      marksman = {},
      texlab = {
        settings = {
          texlab = {
            build = { onSave = true },
            formatterLineLength = 80,
            completion = { matcher = "fuzzy-ignore-case" },
            experimental = { followPackageLinks = true },
          },
        },
      },
      ts_ls = { -- Modern identifier for the TypeScript language server
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
      },
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
            diagnostics = {
              globals = { "vim" }, -- Suppress noisy undefined global 'vim' warnings
            },
          },
        },
      },
    }

    -- Set up mason-lspconfig to manage server installations natively
    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(servers),
      handlers = {
        function(server_name)
          local server_config = servers[server_name] or {}
          -- Inject system-wide capabilities into individual server configurations
          server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})

          -- Pass configurations directly to nvim-lspconfig
          require("lspconfig")[server_name].setup(server_config)
        end,
      },
    })

    -- Global Diagnostic Configuration
    vim.diagnostic.config({
      float = {
        focusable = true,
        style = "compact",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })

    -- LSP Attach Autocommand for Keybindings
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Navigation / Definitions using snacks.nvim pickers
        -- map("grd", function()
        --   Snacks.picker.lsp_definitions()
        -- end, "[G]oto [D]efinition")
        -- map("grr", function()
        --   Snacks.picker.lsp_references()
        -- end, "[G]oto [R]eferences")
        -- map("gri", function()
        --   Snacks.picker.lsp_implementations()
        -- end, "[G]oto [I]mplementation")
        -- map("grt", function()
        --   Snacks.picker.lsp_type_definitions()
        -- end, "Type [D]efinition")
        -- map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        --
        -- Actions
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("gx", vim.lsp.buf.code_action, "[C]ode [A]ction")

        -- Documentation
        -- map("K", function()
        --   vim.lsp.buf.hover({ border = "single" })
        -- end, "Hover LSP info")

        -- Formatting
        vim.keymap.set("n", "<leader>fb", vim.lsp.buf.format, { desc = "[F]ormat Current [B]uffer" })
      end,
    })
  end,
}
