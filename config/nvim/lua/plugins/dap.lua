return {
  "mfussenegger/nvim-dap",
  config = function()
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { desc = "DAP: " .. desc })
    end

    map("<leader>bb", ":lua require('dap').toggle_breakpoint()", "Set [B]reakpoint")
    map(
      "<leader>bc",
      ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))",
      "Set [B]reakpoint [C]onditional"
    )
    map(
      "<leader>bl",
      ":lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))",
      "Set [L]og [B]reakpoint"
    )
    map("<leader>br", ":lua require('dap').clear_breakpoints()", "[C]lear breakpoints")
  end,
}
