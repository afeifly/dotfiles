return {
  -- Kept as a fallback theme option. To switch to e-ink:
  -- 1. Comment out the catppuccin config in cursorline_dim.lua
  -- 2. Uncomment the zenwritten colorscheme line below
  {
    "mcchrish/zenbones.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    lazy = true, -- only load on demand (was lazy=false, now catppuccin is primary)
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- Primary colorscheme is now catppuccin (set in cursorline_dim.lua)
      -- Fallback to zenwritten if catppuccin not found
      colorscheme = vim.g.persisted_colorscheme or "catppuccin",
    },
  },
}
