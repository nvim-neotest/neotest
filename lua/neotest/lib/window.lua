local nio = require("nio")

---@class neotest.PersistentWindow
---@field public name string
---@field _bufnr integer
---@field _win? integer
---@field _open string | function
---@field _bufopts table<string, any>
---@field _winopts table<string, any>
local PersistentWindow = {}

---@class neotest.PersistentWindowOpts
---@field name string
---@field open string | function
---@field bufopts table<string, any>
---@field winopts table<string, any>

---@param opts neotest.PersistentWindowOpts
function PersistentWindow:new(opts)
  self.__index = self
  return setmetatable({
    name = opts.name,
    _winopts = opts.winopts or {},
    _bufopts = opts.bufopts or {},
    _open = opts.open,
    _has_opened = false,
  }, self)
end

---@return integer
function PersistentWindow:open()
  if self:is_open() then
    return self._win
  end

  local cur_win = nio.api.nvim_get_current_win()

  if type(self._open) == "string" then
    vim.cmd(self._open)
    self._win = nio.api.nvim_get_current_win()
  else
    self._win = self._open() or nio.api.nvim_get_current_win()
  end

  nio.api.nvim_set_current_win(cur_win)

  nio.api.nvim_win_set_buf(self._win, self:buffer())

  for k, v in pairs(self._winopts) do
    nio.api.nvim_win_set_option(self._win, k, v)
  end

  if not self._has_opened then
    if self._bufopts.filetype then
      nio.api.nvim_buf_set_option(self:buffer(), "filetype", self._bufopts.filetype)
    end
    self._has_opened = true
  end

  return self._win
end

function PersistentWindow:buffer()
  if
    self._bufnr
    and nio.api.nvim_buf_is_valid(self._bufnr)
    and nio.api.nvim_buf_is_loaded(self._bufnr)
  then
    return self._bufnr
  end

  for _, bufnr in ipairs(nio.api.nvim_list_bufs()) do
    if nio.api.nvim_buf_get_name(bufnr):find(self.name, 1, true) then
      nio.api.nvim_buf_delete(bufnr, { force = true })
    end
  end

  self._bufnr = nio.api.nvim_create_buf(false, true)
  nio.api.nvim_buf_set_name(self._bufnr, self.name)
  for k, v in pairs(self._bufopts) do
    if k ~= "filetype" then
      nio.api.nvim_set_option_value(k, v, { buf = self._bufnr })
    end
  end
  return self._bufnr
end

function PersistentWindow:close()
  if not self:is_open() then
    return
  end
  nio.api.nvim_win_close(self._win, true)
end

function PersistentWindow:is_open()
  return self._win and nio.api.nvim_win_is_valid(self._win)
end

local window_factory = {}

---@param opts neotest.PersistentWindowOpts
function window_factory.new(opts)
  return PersistentWindow:new(opts)
end

---@param opts neotest.PersistentWindowOpts
function window_factory.panel(opts)
  return PersistentWindow:new(vim.tbl_deep_extend("keep", opts, {
    bufopts = {
      modifiable = false,
      buftype = "nofile",
    },
    winopts = {
      winfixwidth = true,
      number = false,
      relativenumber = false,
      spell = false,
    },
  }))
end

return window_factory
