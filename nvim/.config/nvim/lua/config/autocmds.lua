-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Save theme/background state on change
vim.api.nvim_create_autocmd({ "ColorScheme", "OptionSet" }, {
  group = vim.api.nvim_create_augroup("ThemePersistence", { clear = true }),
  pattern = { "*", "background" },
  callback = function()
    local theme_state_path = vim.fn.stdpath("state") .. "/theme_state.lua"
    local state = {
      colorscheme = vim.g.colors_name,
      background = vim.o.background,
    }
    local file = io.open(theme_state_path, "w")
    if file then
      file:write("return " .. vim.inspect(state))
      file:close()
    end
  end,
})
