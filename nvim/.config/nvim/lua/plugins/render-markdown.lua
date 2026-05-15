return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "codecompanion" },
    opts = {
      heading = {
        enabled = true,
        sign = false,
        position = "overlay",
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        backgrounds = {}, 
        foregrounds = {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
        },
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = " " },
      },
    },
    keys = {
      {
        "<leader>cc",
        function()
          local line = vim.api.nvim_get_current_line()
          local checkbox_unfilled = "%[ %]"
          local checkbox_filled = "%[x%]"

          if line:match(checkbox_unfilled) then
            -- [ ] -> [x]
            line = line:gsub(checkbox_unfilled, "[x]")
          elseif line:match(checkbox_filled) then
            -- [x] -> [ ]
            line = line:gsub(checkbox_filled, "[ ]")
          elseif line:match("^%s*%- ") then
            -- List item -> Task item
            line = line:gsub("^(%s*%- )", "%1[ ] ")
          elseif line:match("^%s*%* ") then
            -- Star list item -> Task item
            line = line:gsub("^(%s*%* )", "%1[ ] ")
          else
            -- Normal line -> New Task item
            line = line:gsub("^(%s*)", "%1- [ ] ")
          end

          vim.api.nvim_set_current_line(line)
        end,
        desc = "Toggle/Add Markdown Checkbox",
      },
    },
  },
}
