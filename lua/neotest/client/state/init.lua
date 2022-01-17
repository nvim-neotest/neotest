local logger = require("neotest.logging")

local NeotestEvents = require("neotest.client.events").events
---@class NeotestState
---@field private _focused table<integer, string>
---@field private _positions table<integer, Tree>
---@field private _results table<integer, table<string, Tree> >
---@field private _events NeotestEventProcessor
---@field private _running table<integer, table<string, string>>
---@field private _all_positions Tree
local NeotestState = {}

function NeotestState:new(events)
  local state = {
    _focused = {},
    _positions = {},
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
function NeotestState:positions(adapter_id, position_id)
  if not self._positions[adapter_id] then
    return nil
  end
  if not position_id then
    return self._positions[adapter_id]
  end
  return self._positions[adapter_id]:get_key(position_id)
end

---@return table<string, boolean>
function NeotestState:running(adapter_id)
  return self._running[adapter_id] or {}
end

---@return table<string, NeotestResult>
function NeotestState:results(adapter_id)
  return self._results[adapter_id] or {}
end

---@param tree Tree
function NeotestState:update_positions(adapter_id, tree)
  local root_id = tree:data().id
  logger.debug("New positions at ID", root_id)
  if not self._positions[adapter_id] then
    self._positions[adapter_id] = tree
  elseif tree:data().type == "dir" then
    for _, node in self._positions[adapter_id]:iter_nodes() do
      if node:data().type == "file" then
        local new_file_tree = tree:get_key(node:data().id)
        if new_file_tree and #node:children() > 0 and #new_file_tree:children() == 0 then
          tree:set_key(node:data().id, node)
        end
      end
    end
    self._positions[adapter_id] = tree
  else
    self._positions[adapter_id]:set_key(root_id, tree)
  end
  self._events:emit(NeotestEvents.DISCOVER_POSITIONS, adapter_id, tree)
end

---@param results table<string, NeotestResult>
function NeotestState:update_results(adapter_id, results)
  logger.debug("New results", results)
  self._results[adapter_id] = vim.tbl_extend("force", self._results[adapter_id] or {}, results)
  for id, _ in pairs(results) do
    self._running[adapter_id][id] = nil
  end
  self._events:emit(NeotestEvents.RESULTS, adapter_id, results)
end

function NeotestState:update_running(adapter_id, root_id, position_ids)
  logger.debug("Setting positions to running", root_id, position_ids)
  if not self._running[adapter_id] then
    self._running[adapter_id] = {}
    self._results[adapter_id] = {}
  end
  for _, pos_id in ipairs(position_ids) do
    self._running[adapter_id][pos_id] = root_id
    self._results[adapter_id][pos_id] = nil
  end
  self._events:emit(NeotestEvents.RUN, adapter_id, root_id, position_ids)
end

function NeotestState:update_focused(adapter_id, path)
  self._focused[adapter_id] = path
  self._events:emit(NeotestEvents.TEST_FILE_FOCUSED, adapter_id, path)
end

---@param events NeotestEventProcessor
---@return NeotestState
return function(events)
  return NeotestState:new(events)
end
