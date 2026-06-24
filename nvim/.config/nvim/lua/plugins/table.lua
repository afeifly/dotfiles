return {
  {
    "SCJangra/table-nvim",
    ft = { "markdown" },
    opts = {
      mappings = {
        insert_column_left = "<leader>th",
        insert_column_right = "<leader>tl",
        insert_row_above = "<leader>tk",
        insert_row_below = "<leader>tj",
        delete_column = "<leader>td",
        delete_row = "<leader>to",
        replace_column = "<leader>tc",
        insert_table = "<leader>tt",
      },
    },
    keys = {
      {
        "<leader>tg",
        function()
          vim.ui.input({ prompt = "Table size (rows x cols) [default: 3x3]: " }, function(input)
            local rows, cols = 3, 3
            if input and input ~= "" then
              local r, c = input:match("^(%d+)[xX](%d+)$")
              if r and c then
                rows = tonumber(r)
                cols = tonumber(c)
              else
                vim.notify("Invalid format. Using default 3x3.", vim.log.levels.WARN)
              end
            end

            local lines = {}
            -- Header row
            local header = "|"
            local separator = "|"
            for i = 1, cols do
              header = header .. " Col " .. i .. " |"
              separator = separator .. " --- |"
            end
            table.insert(lines, header)
            table.insert(lines, separator)

            -- Data rows
            for _ = 1, rows do
              local row = "|"
              for _ = 1, cols do
                row = row .. "     |"
              end
              table.insert(lines, row)
            end

            local row_idx = vim.api.nvim_win_get_cursor(0)[1]
            vim.api.nvim_buf_set_lines(0, row_idx, row_idx, false, lines)
            -- Place cursor in the first header column cell
            vim.api.nvim_win_set_cursor(0, { row_idx + 1, 2 })
          end)
        end,
        desc = "Generate custom table",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>t", group = "table" },
        { "<leader>th", desc = "Insert Column Left" },
        { "<leader>tl", desc = "Insert Column Right" },
        { "<leader>tk", desc = "Insert Row Above" },
        { "<leader>tj", desc = "Insert Row Below" },
        { "<leader>td", desc = "Delete Column" },
        { "<leader>to", desc = "Delete Row" },
        { "<leader>tc", desc = "Replace Column" },
        { "<leader>tt", desc = "Insert Table (built-in)" },
        { "<leader>tg", desc = "Generate Table (custom)" },
      },
    },
  },
}
