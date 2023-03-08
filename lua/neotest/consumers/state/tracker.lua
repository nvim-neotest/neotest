---@class neotest.state.State
---@field positions neotest.Tree
---@field running table<string, integer>
---@field status neotest.state.StatusCounts

---@class neotest.state.AdapterState : neotest.state.State
---@field buffers table<string, neotest.state.State>

---@class neotest.state.StateTracker
---@field adapter_states table<string, neotest.state.AdapterState>
---@field adapter_ids string[]
---@field path_buffers table<string, integer>
---@field client neotest.Client
local StateTracker = {}

function StateTracker:new(client)
  local tracker = {
    adapter_states = {},
    client = client,
    adapter_ids = {},
    path_buffers = {},
  }
  self.__index = self
  return setmetatable(tracker, self)
end

---@param buffer integer
---@return neotest.state.State | nil
function StateTracker:buffer_state(adapter_id, buffer)
  local path = vim.fn.fnamemodify(vim.fn.bufname(buffer), ":p")
  local state = self.adapter_states[adapter_id]
  return state.buffers[path]
end

function StateTracker:count_tests(tree)
  local count = 0
  for _, pos in tree:iter() do
    if pos.type == "test" then
      count = count + 1
    end
  end

  return count
end

function StateTracker:is_test(pos_id, tree)
  local node = tree:get_key(pos_id)
  if node and node:data().type == "test" then
    return true
  end
  return false
end

function StateTracker:update_counts(adapter_id)
  local state = self.adapter_states[adapter_id]
  local status = state.status
  local running = state.running
  local tree = state.positions
  status.running = 0
  for _ in pairs(state.running) do
    status.running = status.running + 1
  end
  for _, buf_state in pairs(state.buffers) do
    buf_state.status.running = 0
    for _ in pairs(buf_state.running) do
      buf_state.status.running = buf_state.status.running + 1
    end
  end

  local adapter_results = self.client:get_results(adapter_id)
  status.failed = 0
  status.passed = 0
  status.skipped = 0
  for pos_id, result in pairs(adapter_results) do
    if not running[pos_id] and self:is_test(pos_id, tree) then
      state.status[result.status] = state.status[result.status] + 1
    end
  end
  for _, buf_state in pairs(state.buffers) do
    buf_state.status.failed = 0
    buf_state.status.passed = 0
    buf_state.status.skipped = 0
    for _, pos in buf_state.positions:iter() do
      local result = adapter_results[pos.id]
      if not running[pos.id] and result and self:is_test(pos.id, tree) then
        buf_state.status[result.status] = buf_state.status[result.status] + 1
      end
    end
  end
end

function StateTracker:update_positions(adapter_id)
  local state = self.adapter_states[adapter_id]
  state.positions = assert(self.client:get_position(nil, { adapter = adapter_id }))
  state.status.total = self:count_tests(state.positions)
  for _, node in state.positions:iter_nodes() do
    local pos = node:data()
    if pos.type == "file" and self.path_buffers[pos.path] then
      if not state.buffers[pos.path] then
        state.buffers[pos.path] = {
          positions = node,
          running = {},
          status = {
            failed = 0,
            passed = 0,
            skipped = 0,
            total = 0,
            running = 0,
          },
        }
      end
    end
  end

  for path, buf_state in pairs(state.buffers) do
    local new_tree = state.positions:get_key(path)
    if not new_tree then
      state.buffers[path] = nil
    else
      buf_state.positions = new_tree
      buf_state.status.total = self:count_tests(new_tree)
    end
  end
end

function StateTracker:adapter_state(adapter_id)
  return self.adapter_states[adapter_id]
end

function StateTracker:register_adapter(adapter_id)
  self.adapter_ids[#self.adapter_ids + 1] = adapter_id
  self.adapter_states[adapter_id] = {
    running = {},
    buffers = {},
    status = {
      failed = 0,
      passed = 0,
      skipped = 0,
      total = 0,
      running = 0,
    },
  }
end

function StateTracker:register_buffer(buffer)
  local path = vim.fn.fnamemodify(vim.fn.bufname(buffer), ":p")
  self.path_buffers[path] = buffer
end

function StateTracker:update_running(adapter_id, position_ids)
  local state = self:adapter_state(adapter_id)
  local running = state.running
  local tree = state.positions
  for _, pos_id in ipairs(position_ids) do
    if self:is_test(pos_id, tree) then
      running[pos_id] = (running[pos_id] or 0) + 1
      for _, buf_state in pairs(self:adapter_state(adapter_id).buffers) do
        if buf_state.positions:get_key(pos_id) then
          buf_state.running[pos_id] = (buf_state.running[pos_id] or 0) + 1
        end
      end
    end
  end
  self:update_counts(adapter_id)
end

function StateTracker:decrement_running(adapter_id, results)
  local state = self:adapter_state(adapter_id)
  local running = state.running

  for pos_id, _ in pairs(results) do
    if running[pos_id] then
      running[pos_id] = running[pos_id] - 1
      if running[pos_id] == 0 then
        running[pos_id] = nil
      end
      for _, buf_state in pairs(self:adapter_state(adapter_id).buffers) do
        if buf_state.running[pos_id] then
          buf_state.running[pos_id] = buf_state.running[pos_id] - 1
          if buf_state.running[pos_id] == 0 then
            buf_state.running[pos_id] = nil
          end
        end
      end
    end
  end
end

return StateTracker
