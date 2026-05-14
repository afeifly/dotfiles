return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      overrides = {
        -- 1. 继续保持淡化的当前行高亮 (针对浅色模式)
        CursorLine = { bg = "#f2e5bc" }, 

        -- 2. 让 Markdown 标题颜色更淡、更轻盈
        -- H1 现在不再加粗，并且使用温和的灰色，减少压迫感
        RenderMarkdownH1 = { fg = "#7c6f64", bold = false }, 
        RenderMarkdownH2 = { fg = "#928374", bold = false }, 
        RenderMarkdownH3 = { fg = "#a89984", bold = false },
        RenderMarkdownH4 = { fg = "#a89984" },
        RenderMarkdownH5 = { fg = "#a89984" },
        RenderMarkdownH6 = { fg = "#a89984" },

        -- 确保所有渲染组都同步更新
        ["@markup.heading.1.markdown"] = { link = "RenderMarkdownH1" },
        ["@markup.heading.2.markdown"] = { link = "RenderMarkdownH2" },
        ["@markup.heading.3.markdown"] = { link = "RenderMarkdownH3" },
        ["@markup.heading.4.markdown"] = { link = "RenderMarkdownH4" },
        ["@markup.heading.5.markdown"] = { link = "RenderMarkdownH5" },
        ["@markup.heading.6.markdown"] = { link = "RenderMarkdownH6" },
      }
    }
  }
}
