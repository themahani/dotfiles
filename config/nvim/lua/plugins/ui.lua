return {
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  {
    "rcarriga/nvim-notify",
    config = function()
      local notify = require("notify")
      notify.setup({
        background_colour = "#000000",
        fps = 30,
        timeout = 2000, -- in [ms]
        render = "compact",
        stages = "fade",
        time_formats = {
          notification = "%T",
          notification_history = "%FT%T",
        },
        top_down = true,
      })
      vim.notify = notify.notify
    end,
  },
}
