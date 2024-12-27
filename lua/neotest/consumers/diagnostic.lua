local config = require("neotest.config")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local nio = require("nio")

local function init(client)
  local api = nio.api
  local diag = vim.diagnostic

  local tracking_namespace = api.nvim_create_namespace("_neotest_diagnostic_tracking")
  local diag_namespace = api.nvim_create_namespace("neotest")

  ---@type table<string, BufferDiagnostics>
  local buf_diags = {}

  ---@class BufferDiagnostics
  ---@field bufnr integer
  ---@field file_path string
  ---@field tracking_marks table<string, integer>
  ---@field error_code_lines table<string, string>
  ---@field adapter_id integer
  local BufferDiagnostics = {}

  function BufferDiagnostics:new(bufnr, file_path, adapter_id)
    local buf_diag = {
      bufnr = bufnr,
      file_path = file_path,
      tracking_marks = {},
      error_code_lines = {},
      adapter_id = adapter_id,
    }
    self.__index = self
    setmetatable(buf_diag, self)
    nio.api.nvim_buf_attach(bufnr, false, {
      on_lines = function()
        buf_diag:draw_buffer()
      end,
    })
    return buf_diag
  end

  function BufferDiagnostics:draw_buffer()
    local positions = client:get_position(self.file_path, { adapter = self.adapter_id })
    if not positions then
      return
    end
    for pos_id, _ in pairs(self.tracking_marks) do
      if not positions:get_key(pos_id) then
        self:clear_mark(pos_id)
      end
    end
    local results = client:get_results(self.adapter_id)

    local diagnostics = self:create_diagnostics(positions, results)
    logger.debug("Setting diagnostics for", self.file_path, diagnostics)

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(self.bufnr) then
        return
      end
      diag.set(diag_namespace, self.bufnr, diagnostics)
    end)
  end

  function BufferDiagnostics:clear_mark(pos_id)
    local marks = self.tracking_marks[pos_id]
    if not marks then
      return
    end
    self.tracking_marks[pos_id] = nil
    self.error_code_lines[pos_id] = nil
    for _, mark in pairs(marks) do
      api.nvim_buf_del_extmark(self.bufnr, tracking_namespace, mark)
    end
  end

  function BufferDiagnostics:create_diagnostics(positions, results)
    local bufnr = self.bufnr
    local diagnostics = {}
    for _, position in positions:iter() do
      local pos_id = position.id
      local result = results[pos_id]
      if position.type == "test" and result and result.errors and #result.errors > 0 then
        local pos_by_id = positions:get_key(pos_id)
        local default_line = pos_by_id and pos_by_id:closest_value_for("range")[1]
        local placed = self.tracking_marks[pos_id]
          or self:init_mark(pos_id, result.errors, default_line)
        if placed then
          for error_i, error in pairs(result.errors or {}) do
            local mark = api.nvim_buf_get_extmark_by_id(
              bufnr,
              tracking_namespace,
              self.tracking_marks[pos_id][error_i],
              {}
            )

            -- After closing the buf, the mark[1] becomes nil
            if mark and #mark > 0 then
              local mark_code = api.nvim_buf_get_lines(bufnr, mark[1], mark[1] + 1, false)[1]

              if mark_code == self.error_code_lines[pos_id][error_i] then
                local col = mark_code:find("%S")
                if col then
                  col = col - 1
                else
                  col = 0
                end

                diagnostics[#diagnostics + 1] = {
                  lnum = mark[1],
                  col = col,
                  message = error.message,
                  source = "neotest",
                  severity = config.diagnostic.severity,
                }
              end
            end
          end
        end
      end
    end
    return diagnostics
  end

  function BufferDiagnostics:init_mark(pos_id, errors, default_line)
    local marks = {}
    local error_lines = {}
    for error_i, error in pairs(errors) do
      local line = error.line or default_line
      local success, mark_id = pcall(
        api.nvim_buf_set_extmark,
        self.bufnr,
        tracking_namespace,
        line,
        0,
        { end_line = line }
      )
      if not success then
        logger.error("Failed to place mark for buf", self.bufnr, mark_id)
        return false
      end
      marks[error_i] = mark_id
      error_lines[error_i] = api.nvim_buf_get_lines(self.bufnr, line, line + 1, false)[1]
    end
    self.tracking_marks[pos_id] = marks
    self.error_code_lines[pos_id] = error_lines
    return true
  end

  local function draw_buffer(path, adapter_id)
    if not buf_diags[path] then
      local bufnr = nio.fn.bufnr(path)
      if bufnr == -1 or nio.fn.buflisted(bufnr) == 0 then
        return
      end
      if not client:get_results(adapter_id)[path] then
        local tree = client:get_position(path, { adapter = adapter_id })
        if not tree then
          return
        end
        local results = client:get_results(adapter_id)
        local has_result = false
        for _, pos in tree:iter() do
          if results[pos.id] then
            has_result = true
            break
          end
        end
        if not has_result then
          return
        end
      end
      buf_diags[path] = BufferDiagnostics:new(bufnr, path, adapter_id)
    end
    buf_diags[path]:draw_buffer()
  end

  client.listeners.test_file_focused = function(adapter_id, file_path)
    draw_buffer(adapter_id, file_path)
  end

  client.listeners.discover_positions = function(adapter_id, tree)
    for _, pos in tree:iter() do
      if pos.type == "file" then
        draw_buffer(pos.path, adapter_id)
      end
    end
  end

  client.listeners.run = function(adapter_id, _, position_ids)
    local files = {}
    for _, pos_id in pairs(position_ids) do
      local node = client:get_position(pos_id, { adapter = adapter_id })
      if node then
        local file = node:data().path
        files[file] = files[file] or {}
        table.insert(files[file], pos_id)
      end
    end
    for file_path, to_clear in pairs(files) do
      if buf_diags[file_path] then
        local buf_diag = buf_diags[file_path]
        for _, pos_id in pairs(to_clear) do
          buf_diag:clear_mark(pos_id)
        end
        buf_diags[file_path]:draw_buffer()
      end
    end
  end

  client.listeners.results = function(adapter_id, results)
    local files = {}
    local tree = client:get_position(nil, { adapter = adapter_id })
    if not tree then
      return
    end
    --- Could be thousands of file paths in the results. To avoid checking if each one is loaded which involves a
    --- vimscript call to bufnr, we create the set of buffers that are loaded and check against that.
    local valid_bufs = {}
    for _, bufnr in ipairs(nio.api.nvim_list_bufs()) do
      local valid, name = pcall(nio.api.nvim_buf_get_name, bufnr)
      if valid then
        local bufpath, _ = lib.files.path.real(name)
        if bufpath then
          valid_bufs[bufpath] = true
        end
      end
    end

    for pos_id, _ in pairs(results) do
      local node = tree:get_key(pos_id)
      if node and node:data().type ~= "dir" and valid_bufs[node:data().path] then
        files[node:data().path] = true
      end
    end
    for file_path, _ in pairs(files) do
      draw_buffer(file_path, adapter_id)
    end
  end
end

local neotest = {}
---@toc_entry Diagnostic Consumer
---@text
--- A consumer that displays error messages using the vim.diagnostic API.
--- This consumer is completely passive and so has no interface.
---
--- You can configure the diagnostic API for neotest using the "neotest" namespace
---@seealso |vim.diagnostic.config()|
---@class neotest.consumers.diagnostic
neotest.diagnostic = {}
neotest.diagnostic = setmetatable(neotest.diagnostic, {
  __call = function(_, ...)
    return init(...)
  end,
})

return neotest.diagnostic
