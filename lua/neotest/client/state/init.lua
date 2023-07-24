local logger = require("neotest.logging")
local lib = require("neotest.lib")

local NeotestEvents = require("neotest.client.events").events
---@class neotest.ClientState
---@field private _focused_position table<string, string>
---@field private _focused_file table<string, string>
---@field private _positions table<integer, neotest.Tree>
---@field private _results table<integer, table<string, neotest.Tree> >
---@field private _events neotest.EventProcessor
---@field private _running table<integer, table<string, string>>
---@field private _all_positions neotest.Tree
local NeotestClientState = {}

function NeotestClientState:new(events)
  local state = {
    _focused_file = {},
    _focused_position = {},
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
---@return neotest.Tree | nil
function NeotestClientState:positions(adapter_id, position_id)
  if not self._positions[adapter_id] then
    return nil
  end
  if not position_id then
    return self._positions[adapter_id]
  end
  return self._positions[adapter_id]:get_key(position_id)
end

---@return table<string, boolean>
function NeotestClientState:running(adapter_id)
  return self._running[adapter_id] or {}
end

---@return table<string, neotest.Result>
function NeotestClientState:results(adapter_id)
  return self._results[adapter_id] or {}
end

---@param tree neotest.Tree
function NeotestClientState:update_positions(adapter_id, tree)
  local root_id = tree:data().id
  logger.debug("New positions at ID", root_id)
  if not self._positions[adapter_id] then
    if tree:data().type ~= "dir" then
      logger.info("File discovered without root, using cwd", root_id)
      local root = lib.files.parse_dir_from_files(vim.loop.cwd(), { tree:data().path })
      tree = lib.positions.merge(tree, root)
    end
    self._positions[adapter_id] = tree
  else
    self._positions[adapter_id] = lib.positions.merge(self._positions[adapter_id], tree)
  end
  self._events:emit(NeotestEvents.DISCOVER_POSITIONS, adapter_id, tree)
end

---@param results table<string, neotest.Result>
function NeotestClientState:update_results(adapter_id, results, partial)
  logger.debug("New results for adapter", adapter_id)
  logger.trace(results)
  self._results[adapter_id] = vim.tbl_extend("force", self._results[adapter_id] or {}, results)
  if not self._running[adapter_id] then
    self._running[adapter_id] = {}
  end
  if not partial then
    for id, _ in pairs(results) do
      self._running[adapter_id][id] = nil
    end
  end
  self._events:emit(NeotestEvents.RESULTS, adapter_id, results, partial or false)
end

function NeotestClientState:update_running(adapter_id, root_id, position_ids)
  logger.debug("Setting positions to running", root_id)
  logger.trace(position_ids)
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

function NeotestClientState:update_focused_file(adapter_id, path)
  self._focused_file[adapter_id] = path
  self._events:emit(NeotestEvents.TEST_FILE_FOCUSED, adapter_id, path)
end

function NeotestClientState:update_focused_position(adapter_id, pos_id)
  self._focused_position[adapter_id] = pos_id
  self._events:emit(NeotestEvents.TEST_FOCUSED, adapter_id, pos_id)
end

---@param events neotest.EventProcessor
---@return neotest.ClientState
return function(events)
  return NeotestClientState:new(events)
end
