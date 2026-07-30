-- LSP Configuration
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "mason-org/mason.nvim",
      config = true, -- Automatically runs require("mason").setup()
    },
    "mason-org/mason-lspconfig.nvim",
    {
      "saghen/blink.cmp",
      dependencies = { "rafamadriz/friendly-snippets" }, -- Provides snippets
      version = "*", -- Use latest stable release tag
      opts = {
        keymap = {
          preset = "default",
          ["<CR>"] = { "accept", "fallback" }, -- require return key to accept suggestion
        },
        appearance = {
          nerd_font_variant = "mono",
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },
        completion = {
          accept = {
            auto_brackets = { enabled = true },
          },
          documentation = {
            auto_show = true, -- Automatically show doc window when selecting
            auto_show_delay_ms = 250, -- Delay in milliseconds before showing doc window
          },
        },
        signature = { enabled = true }, -- Displays signature help during typing
      },
      opts_extend = { "sources.default" },
    },
  },

  config = function()
    -- Get default capabilities from Neovim, expanded with blink.cmp capabilities
    local capabilities = require("blink.cmp").get_lsp_capabilities()

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
      jdtls = {},
      ltex_plus = {
        settings = {
          ltex = {
            language = "en-US",
            additionalRules = {
              enablePickyRules = true,
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

        -- Actions
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("gx", vim.lsp.buf.code_action, "[C]ode [A]ction")

        -- Formatting
        vim.keymap.set("n", "<leader>fb", vim.lsp.buf.format, { desc = "[F]ormat Current [B]uffer" })
      end,
    })
  end,
}
