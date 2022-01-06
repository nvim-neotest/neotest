local logger = require("neotest.logging")
local async = require("plenary.async")
local consumer_name = "neotest-diagnostic"

---@param client NeotestClient
return function(client)
  local api = async.api
  local diag = vim.diagnostic

  local tracking_namespace = api.nvim_create_namespace("_ultest_diagnostic_tracking")
  local diag_namespace = api.nvim_create_namespace("neotest_diagnostic")

  ---@type table<string, BufferDiagnostics>
  local buf_diags = {}

  ---@class BufferDiagnostics
  ---@field bufnr integer
  ---@field file_path string
  ---@field tracking_marks table<string, integer>
  ---@field error_code_lines table<string, string>
  local BufferDiagnostics = {}

  function BufferDiagnostics:new(bufnr, file_path)
    local buf_diag = {
      bufnr = bufnr,
      file_path = file_path,
      tracking_marks = {},
      error_code_lines = {},
    }
    self.__index = self
    setmetatable(buf_diag, self)
    async.api.nvim_buf_attach(bufnr, false, {
      on_lines = function()
        buf_diag:draw_buffer()
      end,
    })
    return buf_diag
  end

  function BufferDiagnostics:draw_buffer()
    local positions = client:get_position(self.file_path, false)
    if not positions then
      return
    end
    for pos_id, _ in pairs(self.tracking_marks) do
      if not positions:get_key(pos_id) then
        self:clear_mark(pos_id)
      end
    end
    local results = client:get_results()

    local diagnostics = self:create_diagnostics(positions, results)
    logger.debug("Setting diagnostics for", self.file_path, diagnostics)

    vim.schedule(function()
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
        if not self.tracking_marks[pos_id] then
          self:init_mark(pos_id, result.errors, positions:get_key(pos_id):data().range[1])
        end
        for error_i, error in pairs(result.errors or {}) do
          local mark = api.nvim_buf_get_extmark_by_id(
            bufnr,
            tracking_namespace,
            self.tracking_marks[pos_id][error_i],
            {}
          )
          local mark_code = api.nvim_buf_get_lines(bufnr, mark[1], mark[1] + 1, false)[1]
          if mark_code == self.error_code_lines[pos_id][error_i] then
            diagnostics[#diagnostics + 1] = {
              lnum = mark[1],
              col = 0,
              message = error.message,
              source = "neotest",
            }
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
      marks[error_i] = api.nvim_buf_set_extmark(
        self.bufnr,
        tracking_namespace,
        line,
        0,
        { end_line = line }
      )
      error_lines[error_i] = api.nvim_buf_get_lines(self.bufnr, line, line + 1, false)[1]
    end
    self.tracking_marks[pos_id] = marks
    self.error_code_lines[pos_id] = error_lines
  end

  vim.cmd([[
    augroup NeotestDiagnosticsRefresh
      au!
      au BufEnter * lua require("neotest").diagnostics.render(vim.fn.expand("<afile>:p"))
    augroup END
  ]])

  local function draw_buffer(path)
    if not client:get_results()[path] then
      return
    end
    if not buf_diags[path] then
      local bufnr = async.api.nvim_eval("bufnr('" .. path .. "')")
      if bufnr == -1 then
        return
      end
      buf_diags[path] = BufferDiagnostics:new(bufnr, path)
    end
    buf_diags[path]:draw_buffer()
  end

  client.listeners.discover_positions[consumer_name] = function(tree)
    local path = tree:data().id
    draw_buffer(path)
  end

  client.listeners.run[consumer_name] = function(_, position_ids)
    local files = {}
    for _, pos_id in pairs(position_ids) do
      local node = client:get_position(pos_id)
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

  client.listeners.results[consumer_name] = function(results)
    local files = {}
    for pos_id, _ in pairs(results) do
      local node = client:get_position(pos_id)
      if node then
        files[node:data().path] = true
      end
    end
    for file_path, _ in pairs(files) do
      if buf_diags[file_path] then
        buf_diags[file_path]:draw_buffer()
      end
    end
  end

  return {
    render = function(file_path)
      draw_buffer(file_path)
    end,
  }
end
