local config = require("neotest.config")
local api = vim.api
local nio = require("nio")

local neotest = { lib = {} }

---@toc_entry Library: UI
---@text
--- Helper functions for UI related tasks.
---@class neotest.lib.ui
neotest.lib.ui = {}

neotest.lib.ui.float = require("neotest.lib.ui.float")

---Wrapper aroung vim.api.nvim_open_term. Forces the terminal window to render at the full size of Neovim.
function neotest.lib.ui.open_term(buf, opts)
  -- nvim_open_term uses the current window for determining width/height for truncating lines
  local success, temp_win = pcall(nio.api.nvim_open_win, 0, true, {
    relative = "editor",
    width = nio.api.nvim_get_option("columns"),
    height = nio.api.nvim_get_option("lines"),
    row = 0,
    col = 0,
  })
  local chan = nio.api.nvim_open_term(buf, opts or {})
  if success then
    nio.api.nvim_win_close(temp_win, true)
  end
  return chan
end

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

neotest.lib.ui.open_buf = function(bufnr, line, column)
  local function set_win_pos(win)
    if line then
      api.nvim_win_set_cursor(win, { line + 1, column })
    end
    if api.nvim_win_is_valid(win) then
      api.nvim_set_current_win(win)
    else
      print("Attempted to set an invalid window as current.")
    end
  end

  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr then
      set_win_pos(win)
      return
    end
  end

  local success, win = pcall(select_win)
  if not success or not win then
    print("Failed to select a window for buffer: " .. bufnr)
    return
  end
  if api.nvim_buf_is_valid(bufnr) and api.nvim_win_is_valid(win) then
    api.nvim_win_set_buf(win, bufnr)
    set_win_pos(win)
  else
    print("Buffer or window is not valid.")
  end
end
return neotest.lib.ui
