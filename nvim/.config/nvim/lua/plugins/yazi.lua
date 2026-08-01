return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>e",
      "<cmd>Yazi<cr>",
      desc = "Open Yazi at the current file",
    },
    {
      "<leader>E",
      "<cmd>Yazi cwd<cr>",
      desc = "Open Yazi in working directory" ,
    },
    {
      "<c-y>",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume last Yazi session",
    },
  },
  opts = {
    open_for_directories = false,
    -- Configure image preview for Yazi inside Neovim
    floating_window_scaling_factor = 0.9,
    yazi_floating_window_winblend = 0,
    keymaps = {
      show_help = '<f1>',
    },
  },
}
