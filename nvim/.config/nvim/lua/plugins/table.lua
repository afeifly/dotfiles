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
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>t", group = "+table" },
      },
    },
  },
}
