-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.clipboard = "unnamedplus"

-- Load persisted theme/background
local theme_state_path = vim.fn.stdpath("state") .. "/theme_state.lua"
local f = loadfile(theme_state_path)
if f then
  local state = f()
  if state.background then vim.opt.background = state.background end
  if state.colorscheme then 
    vim.g.persisted_colorscheme = state.colorscheme
  end
end
