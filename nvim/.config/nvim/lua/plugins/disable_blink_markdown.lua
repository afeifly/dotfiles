return {
  {
    "saghen/blink.cmp",
    opts = {
      enabled = function()
        -- 针对 markdown 和 txt 彻底禁用 blink
        local ft = vim.bo.filetype
        if ft == "markdown" or ft == "plain" or ft == "text" then
          return false
        end
        return true
      end,
    },
  },
}
