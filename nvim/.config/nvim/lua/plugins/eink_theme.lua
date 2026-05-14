return {
  {
    "mcchrish/zenbones.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    lazy = false,
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "zenwritten",
    },
  },
  {
    "mcchrish/zenbones.nvim",
    opts = {
      light_variant = "zenwritten",
    },
    config = function()
      vim.opt.background = "light"
      vim.cmd("colorscheme zenwritten")
      
      -- E-ink 专用高亮覆盖
      -- 1. 彻底去掉当前行背景色
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", underline = true, sp = "#000000" })
      
      -- 2. 强制去掉所有标题的背景色，仅保留纯黑文字
      local no_bg_black = { fg = "#000000", bg = "NONE", bold = true }
      vim.api.nvim_set_hl(0, "RenderMarkdownH1", no_bg_black)
      vim.api.nvim_set_hl(0, "RenderMarkdownH2", no_bg_black)
      vim.api.nvim_set_hl(0, "RenderMarkdownH3", no_bg_black)
      vim.api.nvim_set_hl(0, "RenderMarkdownH4", no_bg_black)
      vim.api.nvim_set_hl(0, "RenderMarkdownH5", no_bg_black)
      vim.api.nvim_set_hl(0, "RenderMarkdownH6", no_bg_black)
      
      -- 同步覆盖标准组
      vim.api.nvim_set_hl(0, "@markup.heading.1.markdown", no_bg_black)
      vim.api.nvim_set_hl(0, "@markup.heading.2.markdown", no_bg_black)
      vim.api.nvim_set_hl(0, "@markup.heading.3.markdown", no_bg_black)
    end
  }
}
