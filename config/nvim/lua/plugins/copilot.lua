return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = false,
        trigger_on_accept = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-w>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    })
  end,
}
