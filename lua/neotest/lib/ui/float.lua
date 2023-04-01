local nio = require("nio")
local api = nio.api
local config = require("neotest.config")

local M = {}

---@class neotest.Float
local Float = { win_id = nil, listeners = { close = {} }, position = {} }

local function create_opts(content_width, content_height, position)
  local screen_row = position.line
  local screen_col = position.col

  local vert_anchor = "N"
  local hor_anchor = "W"

  local max_height = config.floating.max_height or vim.o.lines
  local max_width = config.floating.max_width or vim.o.columns
  local border = config.floating.border
  if 0 < max_height and max_height < 1 then
    max_height = math.floor(vim.o.lines * max_height)
  end
  if 0 < max_width and max_width < 1 then
    max_width = math.floor(vim.o.columns * max_width)
  end
  local height = math.min(content_height, max_height - 2)
  local width = math.min(content_width, max_width - 2)

  local row = screen_row + math.min(0, vim.o.lines - (height + screen_row + 3))
  local col = screen_col + math.min(0, vim.o.columns - (width + screen_col + 3))

  return {
    relative = "editor",
    row = row,
    col = col,
    anchor = vert_anchor .. hor_anchor,
    width = width,
    height = height,
    style = "minimal",
    border = border,
    noautocmd = true,
  }
end

function Float:new(win_id, position)
  local win = {}
  setmetatable(win, self)
  self.__index = self
  win.win_id = win_id
  win.position = position
  return win
end

function Float:listen(event, callback)
  self.listeners[event][#self.listeners[event] + 1] = callback
end

function Float:resize(width, height)
  local opts = create_opts(width, height, self.position)
  api.nvim_win_set_config(self.win_id, opts)
end

function Float:get_buf()
  local pass, win = pcall(api.nvim_win_get_buf, self.win_id)
  if not pass then
    return -1
  end
  return win
end

function Float:jump_to()
  api.nvim_set_current_win(self.win_id)
end

function Float:is_floating()
  return api.nvim_win_is_valid(self.win_id) and api.nvim_win_get_config(self.win_id).relative ~= ""
end

function Float:close(force)
  if not force and api.nvim_get_current_win() == self.win_id then
    return false
  end
  local buf = self:get_buf()
  pcall(api.nvim_win_close, self.win_id, true)
  for _, listener in pairs(self.listeners.close) do
    listener({ buffer = buf })
  end
  return true
end

-- settings:
--   Required:
--     height
--     width
--   Optional:
--     buffer
--     position
function M.open(settings)
  local position = settings.position or { line = nio.fn.screenrow(), col = nio.fn.screencol() }
  local opts = create_opts(settings.width, settings.height, position)
  local content_buffer = settings.buffer or api.nvim_create_buf(false, true)
  local win_id = api.nvim_open_win(content_buffer, settings.enter or false, opts)
  api.nvim_exec("redraw", false)

  vim.api.nvim_win_set_option(win_id, "wrap", false)
  for name, val in pairs(config.floating.options) do
    vim.api.nvim_win_set_option(win_id, name, val)
  end

  ---@type neotest.Float
  local win = Float:new(win_id, position)

  if settings.auto_close ~= false then
    local function auto_close()
      if not win:is_floating() then
        -- if no longer a floating window (e.g., moved through wincmd H/J/K/L),
        -- do not bind the autocmd again so the window won't be automatically closed afterwards.
        return
      end
      if not win:close(false) then
        vim.api.nvim_create_autocmd(
          { "WinEnter", "CursorMoved" },
          { callback = auto_close, once = true }
        )
      end
    end
    vim.api.nvim_create_autocmd(
      { "WinEnter", "CursorMoved" },
      { callback = auto_close, once = true }
    )
  end
  return win
end

return M
