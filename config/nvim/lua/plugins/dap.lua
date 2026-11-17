-- Debug Adapter Configuration
local function python_path()
  local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if venv then
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
    { "igorlfs/nvim-dap-view", opts = { auto_toggle = true } }, -- Opens and closes with each session
  },
  keys = {
    {
      "<F5>",
      function()
        require("dap").continue()
      end,
      desc = "DAP: Start/Continue",
    },
    {
      "<F10>",
      function()
        require("dap").step_over()
      end,
      desc = "DAP: Step Over",
    },
    {
      "<F11>",
      function()
        require("dap").step_into()
      end,
      desc = "DAP: Step Into",
    },
    {
      "<F12>",
      function()
        require("dap").step_out()
      end,
      desc = "DAP: Step Out",
    },
    {
      "<leader>bb",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "DAP: Toggle [B]reakpoint",
    },
    {
      "<leader>bc",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      desc = "DAP: Set [B]reakpoint [C]onditional",
    },
    {
      "<leader>bl",
      function()
        require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      end,
      desc = "DAP: Set [L]og [B]reakpoint",
    },
    {
      "<leader>br",
      function()
        require("dap").clear_breakpoints()
      end,
      desc = "DAP: Clear breakpoints",
    },
    {
      "<leader>bq",
      function()
        require("dap").terminate()
      end,
      desc = "DAP: [Q]uit session",
    },
    {
      "<leader>bv",
      function()
        require("dap-view").toggle()
      end,
      desc = "DAP: Toggle [V]iew",
    },
  },

  config = function()
    local dap = require("dap")

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
