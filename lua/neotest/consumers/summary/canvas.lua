local M = {}

local api = vim.api
M.namespace = api.nvim_create_namespace("neotest-canvas")

---@class Canvas
---@field lines table
---@field matches table
---@field mappings table
---@field valid boolean
---@field config table
---@field position table
local Canvas = {}

---@return Canvas
function Canvas:new(config)
  local mappings = {}
  local canvas = {
    lines = { "" },
    matches = {},
    mappings = mappings,
    valid = true,
    config = config,
  }
  setmetatable(canvas, self)
  self.__index = self
  return canvas
end

-- Used by components waiting on canvas update to render.
-- This is to avoid flickering updates as information is updated.
function Canvas:invalidate()
  self.valid = false
end

function Canvas:write(text, opts)
  opts = opts or {}
  local lines = vim.split(text, "[\r]?\n", { plain = false })
  for i, line in pairs(lines) do
    local cur_line = self.lines[#self.lines]
    self.lines[#self.lines] = cur_line .. line
    if opts.group and #line > 0 then
      if type(opts.group) == "string" then
        opts.group = { opts.group }
      end
      for _, group in ipairs(opts.group) do
        self.matches[#self.matches + 1] = { group, { #self.lines, #cur_line + 1, #line } }
      end
    end
    if i < #lines then
      table.insert(self.lines, "")
    end
  end
end

function Canvas:position_cursor(line, col)
  self.position = { line = line or self:length(), col = col or 1 }
end

--- Remove the last line from canvas
function Canvas:remove_line()
  self.lines[#self.lines] = nil
end

function Canvas:reset()
  self.lines = {}
  self.matches = {}
  self.mappings = {}
end

---Add a mapping for a specific line
---@param action string Name of mapping action to use key for
---@param callback function Callback for when mapping is used
---@param opts table? Optional extra arguments
-- Extra arguments currently accepts:
--   `line` Line to map to, defaults to last in canvas
function Canvas:add_mapping(action, callback, opts)
  opts = opts or {}
  local line = opts["line"] or self:length()
  if not self.mappings[action] then
    self.mappings[action] = {}
  end
  self.mappings[action][line] = self.mappings[action][line] or {}
  self.mappings[action][line][#self.mappings[action][line] + 1] = callback
end

---Get the number of lines in canvas
function Canvas:length()
  return #self.lines
end

---Get the length of the longest line in canvas
function Canvas:width()
  local width = 0
  for _, line in pairs(self.lines) do
    width = width < #line and #line or width
  end
  return width
end

---Apply a render canvas to a buffer
---@param self Canvas
---@param buffer number
function Canvas:render_buffer(buffer)
  local success, err = pcall(api.nvim_buf_set_option, buffer, "modifiable", true)
  if not success then
    return false, err
  end
  if self:length() == 0 then
    return false, "No lines to render"
  end
  if buffer < 0 then
    return false, "Invalid buffer"
  end
  local win = vim.fn.bufwinid(buffer)
  if win == -1 then
    return false, "Window not found"
  end

  local map_in_visual = { "expand", "expand_all", "mark", "run", "stop" }
  local bufname = vim.fn.bufname(buffer)

  for action, mappings in pairs(self.mappings) do
    local action_keys = self.config.mappings[action]
    if type(action_keys) ~= "table" then
      action_keys = { action_keys }
    end

    for _, key in ipairs(action_keys) do
      vim.api.nvim_buf_set_keymap(buffer, "n", key, "", {
        noremap = true,
        nowait = true,
        callback = function()
          for _, callback in pairs(mappings[vim.fn.line(".")] or {}) do
            callback()
          end
        end,
        desc = string.format("%s (%s)", action, bufname),
      })
      if vim.tbl_contains(map_in_visual, action) then
        vim.api.nvim_buf_set_keymap(buffer, "v", key, "", {
          noremap = true,
          nowait = true,
          callback = function()
            local linenos = { vim.fn.getpos("v")[2], vim.fn.getpos(".")[2] }
            table.sort(linenos)
            for lineno = linenos[1], linenos[2] do
              for _, callback in pairs(mappings[lineno] or {}) do
                callback()
              end
            end
          end,
        })
      end
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
  if self.position and vim.api.nvim_get_current_win() ~= win then
    api.nvim_win_set_cursor(win, { self.position.line, self.position.col - 1 })
  end
  return true
end

--- @return Canvas
function M.new(config)
  return Canvas:new(config)
end

return M
