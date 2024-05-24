local nio = require("nio")
local logger = require("neotest.logging")
local neotest = {}
local StateTracker = require("neotest.consumers.state.tracker")

---@type neotest.state.StateTracker
---@nodoc
local tracker

---@param client neotest.Client
---@nodoc
local function init(client)
  local updated_event = nio.control.event()
  local semaphore = nio.control.semaphore()
  local wrap_listener = function(listener)
    return function(...)
      local args = { ... }
      semaphore.with(function()
        listener(unpack(args))
      end)
    end
  end
  tracker = StateTracker:new(client)
  local function update_positions()
    while true do
      updated_event.wait()
      updated_event.clear()
      for _, adapter_id in ipairs(tracker.adapter_ids) do
        tracker:update_positions(adapter_id)
        tracker:update_counts(adapter_id)
      end
      nio.sleep(50)
    end
  end

  vim.api.nvim_create_autocmd("BufAdd", {
    callback = function(args)
      tracker:register_buffer(args.buf)
      updated_event.set()
    end,
  })
  for _, buf in ipairs(nio.api.nvim_list_bufs()) do
    tracker:register_buffer(buf)
  end
  nio.run(function()
    xpcall(update_positions, function(msg)
      logger.error("Error in state consumer", debug.traceback(msg, 2))
    end)
  end)
  client.listeners.discover_positions = wrap_listener(function(adapter_id)
    if not tracker:adapter_state(adapter_id) then
      tracker:register_adapter(adapter_id)
    end
    updated_event.set()
  end)

  client.listeners.run = wrap_listener(function(adapter_id, _, position_ids)
    tracker:update_running(adapter_id, position_ids)
  end)

  client.listeners.results = wrap_listener(function(adapter_id, results)
    tracker:decrement_running(adapter_id, results)
    updated_event.set()
  end)
end

---@param args? table
---@return neotest.state.State | nil
---@nodoc
local function state_from_args(adapter_id, args)
  if args and args.buffer then
    return tracker:buffer_state(adapter_id, args.buffer)
  end
  return tracker:adapter_state(adapter_id)
end

---@toc_entry State Consumer
---@text
--- A consumer that tracks various pieces of state in Neotest.
--- Most of the internals of Neotest are asynchronous so this consumer allows
--- tracking the state of the test suite and test results without needing to
--- write asynchronous code.
---@class neotest.consumers.state
neotest.state = {}

--- Get the list of all adapter IDs currently active
---@return string[]
function neotest.state.adapter_ids()
  return tracker.adapter_ids
end

--- Get the counts of the various states of tests for the entire suite or for a
--- buffer.
---@param adapter_id string
---@param args? neotest.state.StatusCountsArgs
---@return neotest.state.StatusCounts | nil
function neotest.state.status_counts(adapter_id, args)
  local state = state_from_args(adapter_id, args)

  return state and state.status
end

---@class neotest.state.StatusCountsArgs
---@field buffer? integer Returns statuses for this buffer

---@class neotest.state.StatusCounts
---@field total integer
---@field passed integer
---@field failed integer
---@field skipped integer
---@field running integer

--- Get the known positions for the entire suite or for a buffer.
---@param adapter_id string
---@param args? neotest.state.PositionsArgs
---@return neotest.Tree | nil
function neotest.state.positions(adapter_id, args)
  local state = state_from_args(adapter_id, args)

  return state and state.positions
end

---@class neotest.state.PositionsArgs
---@field buffer? integer Returns positions for this buffer

neotest.summary = setmetatable(neotest.state, {
  __call = function(_, client)
    init(client)
    return neotest.state
  end,
})

return neotest.state
