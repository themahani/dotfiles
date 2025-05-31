-- LSP and Completion Configs
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { -- Mason must be loaded before its dependants
      "williamboman/mason.nvim",
      config = true,
    },
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",

    {
      "saghen/blink.cmp",
      -- optional: provides snippets for the snippet source
      dependencies = {
        "echasnovski/mini.snippets",
        config = function()
          require("mini.snippets").setup({})
        end,
      },

      -- use a release tag to download pre-built binaries
      version = "1.*",
      -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
      -- build = 'cargo build --release',

      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      opts = {
        -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
        -- 'super-tab' for mappings similar to vscode (tab to accept)
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- All presets have the following mappings:
        -- C-space: Open menu or open docs if already open
        -- C-n/C-p or Up/Down: Select next/previous item
        -- C-e: Hide menu
        -- C-k: Toggle signature help (if signature.enabled = true)
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        keymap = { preset = "enter" },

        appearance = {
          -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
          -- Adjusts spacing to ensure icons are aligned
          nerd_font_variant = "mono",
        },

        completion = {
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            window = { border = "single" },
          },
          menu = {
            border = "single",
          },
        },

        signature = {
          enabled = true,
          window = { border = "single" },
        },

        snippets = { preset = "mini_snippets" }, -- Add mini_snippets to sources for snippets

        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },

        -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
        -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
        -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
        --
        -- See the fuzzy documentation for more information
        fuzzy = { implementation = "prefer_rust_with_warning" },
      },
      opts_extend = { "sources.default" },
    },
  },

  -- Configs for LSP
  config = function()
    local blink_cmp = require("blink.cmp")
    local blink_capabilities = blink_cmp.get_lsp_capabilities({}, false)
    -- Extend the capabilities of nvim lsp using cmp
    local capabilities =
      vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities(), blink_capabilities)

    require("mason").setup({})

    -- Servers to ensure_installed with their configs
    local servers = {
      clangd = {},
      pyright = {},
      html = {},
      cssls = {},
      markdown_oxide = {},
      texlab = {
        settings = {
          texlab = {
            build = { onSave = true },
            formatterLineLength = 80,
            completion = { matcher = "fuzzy-ignore-case" }, -- fuzzy[-ignore-case], prefix[-ignore-case]
            experimental = { followPackageLinks = true },
          },
        },
      },
      tailwindcss = {},
      eslint = { -- Linter and Formatter for Web Dev
        settings = {
          eslint = {
            autoFixOneSave = true,
            format = { enable = true },
          },
        },
      },
      ["typescript-language-server"] = { -- LSP for js and ts
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
      },
      black = {}, -- Formatter for Python
      prettier = {}, -- Formatter for javascript / typescript
      stylua = {}, -- Formatter for Lua

      lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = capabilities
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }
    -- Auto install all the configured servers
    local ensure_installed = vim.tbl_keys(servers or {})
    require("mason-tool-installer").setup({
      ensure_installed = ensure_installed,
      automatic_installation = true,
    })
    -- Set up server configs for nvim-lspconfig and nvim-cmp
    local lsp_cmp_setup = function(server_configs)
      for server_name, server_config in pairs(server_configs) do
        vim.lsp.enable(server_name)
        local extended_server_config = vim.tbl_extend("error", { capabilities = capabilities }, server_config)
        vim.lsp.config(server_name, extended_server_config)
      end
    end
    lsp_cmp_setup(servers)

    vim.diagnostic.config({
      -- update_in_insert = true,
      float = {
        focusable = true,
        style = "compact",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        -- map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        -- map("gr", vim.lsp.bug.references, "[G]oto [R]eferences")

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        -- map("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        -- map("<leader>D", vim.lsp.buf.lsp_type_definitions, "Type [D]efinition")

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        -- map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        -- map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        map("K", function()
          vim.lsp.buf.hover({ border = "single" })
        end, "Hover LSP info")

        -- Mapping to format current buffer
        vim.keymap.set("n", "<leader>fb", vim.lsp.buf.format, { desc = "[F]ormat Current [B]uffer" })
      end,
    })
  end,
}
