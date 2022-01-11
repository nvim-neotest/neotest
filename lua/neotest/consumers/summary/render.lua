local M = {}

local _mappings = {}
local api = vim.api
M.namespace = api.nvim_create_namespace("neotest-render")

---@class RenderState
---@field lines table
---@field matches table
---@field mappings table
---@field valid boolean
---@field config table
local RenderState = {}

---@return RenderState
function RenderState:new(config)
  local mappings = {}
  local render_state = {
    lines = { "" },
    matches = {},
    mappings = mappings,
    valid = true,
    config = config,
  }
  setmetatable(render_state, self)
  self.__index = self
  return render_state
end

-- Used by components waiting on state update to render.
-- This is to avoid flickering updates as information is updated.
function RenderState:invalidate()
  self.valid = false
end

function RenderState:write(text, opts)
  opts = opts or {}
  local lines = vim.split(text, "[\r]?\n", false)
  for i, line in pairs(lines) do
    local cur_line = self.lines[#self.lines]
    self.lines[#self.lines] = cur_line .. line
    if opts.group and #line > 0 then
      self:add_match(opts.group, #self.lines, #cur_line + 1, #line)
    end
    if i < #lines then
      table.insert(self.lines, "")
    end
  end
end

--- Remove the last line from state
function RenderState:remove_line()
  self.lines[#self.lines] = nil
end

function RenderState:reset()
  self.lines = {}
  self.matches = {}
  self.mappings = {}
end

---Add a new highlight match to pass to matchaddpos
---@param group string Highlight group
---@param line number Line to add match for
---@param start_col number First column to start match
---@param length number Length of match
function RenderState:add_match(group, line, start_col, length)
  local pos = { line }
  if start_col ~= nil then
    pos[#pos + 1] = start_col
  end
  if length ~= nil then
    pos[#pos + 1] = length
  end
  self.matches[#self.matches + 1] = { group, pos }
end

---Add a mapping for a specific line
---@param action string Name of mapping action to use key for
---@param callback function Callback for when mapping is used
---@param opts table Optional extra arguments
-- Extra arguments currently accepts:
--   `line` Line to map to, defaults to last in state
function RenderState:add_mapping(action, callback, opts)
  opts = opts or {}
  local line = opts["line"] or self:length()
  if not self.mappings[action] then
    self.mappings[action] = {}
  end
  self.mappings[action][line] = self.mappings[action][line] or {}
  self.mappings[action][line][#self.mappings[action][line] + 1] = callback
end

---Get the number of lines in state
function RenderState:length()
  return #self.lines
end

---Get the length of the longest line in state
function RenderState:width()
  local width = 0
  for _, line in pairs(self.lines) do
    width = width < #line and #line or width
  end
  return width
end

---Apply a render state to a buffer
---@param self RenderState
---@param buffer number
function RenderState:render_buffer(buffer)
  local success, _ = pcall(api.nvim_buf_set_option, buffer, "modifiable", true)
  if not success then
    return false
  end
  if self:length() == 0 then
    return
  end
  if buffer < 0 then
    return false
  end
  local win = vim.fn.bufwinnr(buffer)
  if win == -1 then
    return false
  end

  _mappings[buffer] = self.mappings
  for action, _ in pairs(self.mappings) do
    local mappings = self.config.mappings[action]
    for _, key in pairs(mappings) do
      vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        key,
        "<cmd>lua require('neotest.consumers.summary.render')._mapping('" .. action .. "')<CR>",
        { noremap = true }
      )
    end
  end

  local lines = self.lines
  local matches = self.matches
  api.nvim_buf_clear_namespace(buffer, M.namespace, 0, -1)
  api.nvim_buf_set_lines(buffer, 0, #lines, false, lines)
  local last_line = vim.fn.getbufinfo(buffer)[1].linecount
  if last_line > #lines then
    api.nvim_buf_set_lines(buffer, #lines, last_line, false, {})
  end
  for _, match in pairs(matches) do
    local pos = match[2]
    api.nvim_buf_set_extmark(
      buffer,
      M.namespace,
      pos[1] - 1,
      (pos[2] or 1) - 1,
      { end_col = pos[3] and (pos[2] + pos[3] - 1), hl_group = match[1] }
    )
  end
  api.nvim_buf_set_option(buffer, "modifiable", false)
  api.nvim_buf_set_option(buffer, "buftype", "nofile")
  return true
end

--- @return RenderState
function M.new(config)
  return RenderState:new(config)
end

function M._mapping(action)
  local buffer = api.nvim_get_current_buf()
  local line = vim.fn.line(".")
  local callbacks = _mappings[buffer][action] and _mappings[buffer][action][line] or nil
  if not callbacks then
    return
  end
  for _, callback in pairs(callbacks) do
    callback()
  end
end

return M
