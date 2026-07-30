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

-- Save active Neovim server name to /tmp/nvim-current-server.pipe on focus and startup
local nvim_server_group = vim.api.nvim_create_augroup("NvimServerTracker", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "WinEnter" }, {
  group = nvim_server_group,
  callback = function()
    local server = vim.v.servername
    if server and server ~= "" then
      local f = io.open("/tmp/nvim-current-server.pipe", "w")
      if f then
        f:write(server)
        f:close()
      end
    end
  end,
})
