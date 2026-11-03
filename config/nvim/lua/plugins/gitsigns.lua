return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- navigation
      map("n", "]h", function()
        gs.nav_hunk("next")
      end, "Next Hunk")
      map("n", "[h", function()
        gs.nav_hunk("prev")
      end, "Prev Hunk")
      map("n", "]H", function()
        gs.nav_hunk("last")
      end, "Last Hunk")
      map("n", "[H", function()
        gs.nav_hunk("first")
      end, "First Hunk")

      -- actions
      map("n", "<leader>ghs", gs.stage_hunk, "Stage/Unstage Hunk")
      map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")
      map("v", "<leader>ghs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Stage/Unstage Lines")
      map("v", "<leader>ghr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset Lines")
      map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
      map("n", "<leader>ghd", gs.diffthis, "Diff This")
      map("n", "<leader>ghD", function()
        gs.diffthis("~")
      end, "Diff This ~")

      -- blame
      map("n", "<leader>gbb", function()
        gs.blame_line({ full = true })
      end, "Blame Line Commit")
      map("n", "<leader>gbB", gs.blame, "Blame Buffer")
      map("n", "<leader>gbL", gs.toggle_current_line_blame, "Toggle Line Blame")

      -- text object
      map({ "o", "x" }, "ih", gs.select_hunk, "Select Hunk")
    end,
  },
}
