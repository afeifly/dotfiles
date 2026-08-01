return {
  -- colorscheme managed by catppuccin (matches Ghostty Catppuccin Mocha)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      background = { -- auto-switch based on vim.opt.background
        light = "latte",
        dark = "mocha",
      },
      -- flavour = "mocha", -- removed to let background setting handle it
      transparent_background = true, -- let Ghostty's bg show through
      integrations = {
        render_markdown = true,
        gitsigns = true,
        which_key = true,
        mini = true,
        noice = true,
        notify = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
      highlight_overrides = {
        all = function(colors)
          return {
            -- subtle cursorline — just enough to see it, not overpowering
            CursorLine = { bg = colors.surface0 },

            -- softer markdown headings
            RenderMarkdownH1 = { fg = colors.lavender, bold = true },
            RenderMarkdownH2 = { fg = colors.mauve, bold = true },
            RenderMarkdownH3 = { fg = colors.teal, bold = false },
            RenderMarkdownH4 = { fg = colors.subtext1, bold = false },
            RenderMarkdownH5 = { fg = colors.overlay1, bold = false },
            RenderMarkdownH6 = { fg = colors.overlay1, bold = false },
          }
        end,
      },
    },
  },
}
