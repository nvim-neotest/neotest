local logger = require("neotest.logging")

local NeotestEvents = require("neotest.client.events").events
---@class NeotestState
---@field private _positions Tree
---@field private _results table<string, Tree> table
---@field private _events NeotestEventProcessor
---@field private _running table<string, string>
---@field private _all_positions Tree
local NeotestState = {}

function NeotestState:new(events)
  local state = {
    _results = {},
    _events = events,
    _running = {},
  }
  setmetatable(state, self)
  self.__index = self
  return state
end

---@param position_id? string
---@return Tree | nil
function NeotestState:positions(position_id)
  if not self._positions then
    return nil
  end
  if not position_id then
    return self._positions
  end
  return self._positions:get_key(position_id)
end

---@return table<string, boolean>
function NeotestState:running()
  return self._running
end

---@return table<string, NeotestResult>
function NeotestState:results()
  return self._results
end

---@param tree Tree
function NeotestState:update_positions(tree)
  local root_id = tree:data().id
  logger.debug("New positions at ID", root_id)
  logger.trace(tree)
  if not self._positions then
    self._positions = tree
  elseif tree:data().type == "dir" then
    for _, node in self._positions:iter_nodes() do
      if node:data().type == "file" then
        local new_file_tree = tree:get_key(node:data().id)
        if new_file_tree and #node:children() > 0 and #new_file_tree:children() == 0 then
          tree:set_key(node:data().id, node)
        end
      end
    end
    self._positions = tree
  else
    self._positions:set_key(root_id, tree)
  end
  self._events:emit(NeotestEvents.DISCOVER_POSITIONS, tree)
end

---@param results table<string, NeotestResult>
function NeotestState:update_results(results)
  logger.debug("New results", results)
  self._results = vim.tbl_extend("force", self._results, results)
  for id, _ in pairs(results) do
    self._running[id] = nil
  end
  self._events:emit(NeotestEvents.RESULTS, results)
end

function NeotestState:update_running(root_id, position_ids)
  logger.debug("Setting positions to running", root_id, position_ids)
  for _, pos_id in ipairs(position_ids) do
    self._running[pos_id] = root_id
    self._results[pos_id] = nil
  end
  self._events:emit(NeotestEvents.RUN, root_id, position_ids)
end
---@param events NeotestEventProcessor
---@return NeotestState
return function(events)
  return NeotestState:new(events)
end
