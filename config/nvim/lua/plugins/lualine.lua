return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "auto",
        icons_enabled = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {
        lualine_a = {
          {
            "tabs",
            tab_max_length = 40,
            max_length = vim.o.columns / 2,
            mode = 2, -- Show tab number and name
            path = 0, -- Show only the filename
            use_mode_colors = false,
            tabs_color = {
              active = "lualine_a_normal",
              inactive = "lualine_a_inactive",
            },
            show_modified_status = true,
            symbols = {
              modified = "[+]",
            },
            fmt = function(name, context)
              -- Show + if buffer is modified in tab
              local buflist = vim.fn.tabpagebuflist(context.tabnr)
              local winnr = vim.fn.tabpagewinnr(context.tabnr)
              local bufnr = buflist[winnr]
              local mod = vim.fn.getbufvar(bufnr, "&mod")

              return name .. (mod == 1 and " +" or "")
            end,
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          {
            "buffers",
            show_filename_only = true,
            hide_filename_extension = false,
            show_modified_status = true,
            mode = 0, -- Show buffer name
            max_length = vim.o.columns / 2,
            filetype_names = {
              snacks_dashboard = "Dashboard",
            },
            use_mode_colors = true,
            symbols = {
              modified = " ●",
              alternate_file = "#",
              directory = "",
            },
          },
        },
      },
      winbar = {},
      inactive_winbar = {},
      extensions = {},
    })
  end,
}
