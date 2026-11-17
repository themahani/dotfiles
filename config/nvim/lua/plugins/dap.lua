-- Debug Adapter Configuration
local function python_path()
  local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if not venv then
    -- uv and `python -m venv` projects usually aren't activated in the shell,
    -- so look for a project venv above the file being debugged.
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then
      dir = vim.fn.getcwd()
    end
    venv = vim.fs.find({ ".venv", "venv" }, { upward = true, type = "directory", path = dir })[1]
  end
  if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
    return venv .. "/bin/python"
  end
  return vim.fn.exepath("python3")
end

local function pick_executable()
  return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
end

local codelldb_launch = {
  {
    name = "Launch executable",
    type = "codelldb",
    request = "launch",
    program = pick_executable,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

return {
  "mfussenegger/nvim-dap",
  event = "VeryLazy",
  dependencies = {
    "mason-org/mason.nvim", -- Puts Mason's bin directory on PATH
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "nvim-neotest/nvim-nio" },
      config = function()
        local dap, dapui = require("dap"), require("dapui")
        dapui.setup()

        -- Open the UI when a session starts and close it when it ends
        dap.listeners.before.attach.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
          dapui.close()
        end
      end,
    },
  },
  keys = {
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
      desc = "DAP: Start/Continue",
    },
    {
      "<leader>dsO",
      function()
        require("dap").step_over()
      end,
      desc = "DAP: Step Over",
    },
    {
      "<leader>dsi",
      function()
        require("dap").step_into()
      end,
      desc = "DAP: Step Into",
    },
    {
      "<leader>dso",
      function()
        require("dap").step_out()
      end,
      desc = "DAP: Step Out",
    },
    {
      "<leader>dbb",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "DAP: Toggle [B]reakpoint",
    },
    {
      "<leader>dbc",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      desc = "DAP: Set [B]reakpoint [C]onditional",
    },
    {
      "<leader>dbl",
      function()
        require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      end,
      desc = "DAP: Set [L]og [B]reakpoint",
    },
    {
      "<leader>dbr",
      function()
        require("dap").clear_breakpoints()
      end,
      desc = "DAP: Clear breakpoints",
    },
    {
      "<leader>dq",
      function()
        require("dap").terminate()
      end,
      desc = "DAP: [Q]uit session",
    },
    {
      "<leader>dv",
      function()
        require("dapui").toggle()
      end,
      desc = "DAP: Toggle [V]iew",
    },
  },

  config = function()
    local dap = require("dap")

    -- Sign column icons (Nerd Font codicons) and their colors. The built-in
    -- catppuccin has no Diagnostic* groups, so link to core groups it defines.
    local signs = {
      DapBreakpoint = { text = "", hl = "Error" }, -- circle_filled
      DapBreakpointCondition = { text = "", hl = "WarningMsg" }, -- debug_breakpoint_conditional
      DapLogPoint = { text = "", hl = "Changed" }, -- debug_breakpoint_log
      DapBreakpointRejected = { text = "", hl = "NonText" }, -- debug_breakpoint_unsupported
      DapStopped = { text = "", hl = "Added", line = "DapStoppedLine" }, -- debug_stackframe_active
    }
    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    for name, sign in pairs(signs) do
      vim.api.nvim_set_hl(0, name, { default = true, link = sign.hl })
      vim.fn.sign_define(name, { text = sign.text, texthl = name, linehl = sign.line or "", numhl = "" })
    end

    -- Map out debug adapters by Mason package name. Each entry registers its
    -- adapters and the launch configurations for its filetypes.
    local debuggers = {
      debugpy = {
        adapters = {
          debugpy = { type = "executable", command = "debugpy-adapter" },
        },
        configurations = {
          python = {
            {
              name = "Launch file",
              type = "debugpy",
              request = "launch",
              program = "${file}",
              pythonPath = python_path,
              console = "integratedTerminal",
            },
          },
        },
      },
      codelldb = {
        adapters = {
          codelldb = { type = "executable", command = "codelldb" },
        },
        configurations = {
          c = codelldb_launch,
          cpp = codelldb_launch,
        },
      },
    }

    local selected = require("dotfiles-options").debuggers
    if selected then
      local enabled = {}
      for _, name in ipairs(selected) do
        enabled[name] = debuggers[name] or {}
      end
      debuggers = enabled
    end

    for _, debugger in pairs(debuggers) do
      for name, adapter in pairs(debugger.adapters or {}) do
        dap.adapters[name] = adapter
      end
      for filetype, configurations in pairs(debugger.configurations or {}) do
        dap.configurations[filetype] = configurations
      end
    end

    -- Install missing adapters from the Mason registry
    local registry = require("mason-registry")
    registry.refresh(function()
      for name in pairs(debuggers) do
        if not registry.has_package(name) then
          vim.notify("Unknown Mason package for DAP: " .. name, vim.log.levels.WARN)
        elseif not registry.is_installed(name) then
          registry.get_package(name):install()
        end
      end
    end)
  end,
}
