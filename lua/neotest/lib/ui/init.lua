local config = require("neotest.config")
local api = vim.api

local M = {}

M.float = require("neotest.lib.ui.float")

local function set_opts(win, opts)
  for opt, value in pairs(opts) do
    api.nvim_win_set_option(win, opt, value)
  end
end

local function select_win()
  local windows = vim.tbl_filter(function(win)
    if api.nvim_win_get_config(win).relative ~= "" then
      return false
    end
    local buf = api.nvim_win_get_buf(win)
    return api.nvim_buf_get_option(buf, "buftype") == ""
  end, api.nvim_tabpage_list_wins(0))

  if #windows < 2 then
    return windows[1]
  end

  local overwritten_opts = {}
  local laststatus = vim.o.laststatus
  vim.o.laststatus = 2

  for i, win in ipairs(windows) do
    overwritten_opts[win] = {
      statusline = api.nvim_win_get_option(win, "statusline"),
      winhl = api.nvim_win_get_option(win, "winhl"),
    }
    set_opts(win, {
      statusline = "%=" .. string.char(64 + i) .. "%=",
      winhl = ("StatusLine:%s,StatusLineNC:%s"):format(
        config.highlights.select_win,
        config.highlights.select_win
      ),
    })
  end

  vim.cmd("redrawstatus!")
  local index, char
  local ESC, CTRL_C = 27, 22
  print("Select window: ")
  pcall(function()
    while char ~= ESC and char ~= CTRL_C and not windows[index] do
      char = vim.fn.getchar()
      if type(char) == "number" then
        index = char - 96
      end
    end
  end)

  for win, opts in pairs(overwritten_opts) do
    pcall(set_opts, win, opts)
  end

  vim.o.laststatus = laststatus
  vim.cmd("normal! :")

  return windows[index]
end

M.open_buf = function(bufnr, line, column)
  local function set_win_pos(win)
    if line then
      api.nvim_win_set_cursor(win, { line + 1, column })
    end
    api.nvim_set_current_win(win)
  end

  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr then
      set_win_pos(win)
      return
    end
  end

  local success, win = pcall(select_win)
  if not success or not win then
    return
  end
  api.nvim_win_set_buf(win, bufnr)
  set_win_pos(win)
end

return M
