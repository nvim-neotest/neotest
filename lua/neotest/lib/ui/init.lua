local api = vim.api
local M = {}

M.float = require("neotest.lib.ui.float")

M.open_buf = function(bufnr, line, column)
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr then
      if line then
        api.nvim_win_set_cursor(win, { line - 1, column })
      end
      api.nvim_set_current_win(win)
      return
    end
  end

  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    local winbuf = api.nvim_win_get_buf(win)
    if api.nvim_buf_get_option(winbuf, "buftype") == "" then
      local bufchanged, _ = pcall(api.nvim_win_set_buf, win, bufnr)
      if bufchanged then
        if line then
          api.nvim_win_set_cursor(win, { line - 1, column })
        end
        api.nvim_set_current_win(win)
        return
      end
    end
  end
end

return M
