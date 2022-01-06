local async = require("plenary.async")
local logger = require("neotest.logging")

local M = {}

---@alias NeotestEvent "discover_positions" | "run" | "results"
---@class NeotestEvents
---@field DISCOVER_POSITIONS "discover_positions"
---@field RUN "run"
---@field RESULTS "results"
local NeotestEvents = {
  DISCOVER_POSITIONS = "discover_positions",
  RUN = "run",
  RESULTS = "results",
}

M.events = NeotestEvents

---@class NeotestEventListeners
---@field discover_files table<string, fun(files: string[])>
---@field discover_positions table<string, fun(file_path: string, tree: Tree)>
---@field run table<string, fun(position_ids: string[])>
---@field results table<string, fun(results: table<string, NeotestResult>)>

---@class NeotestEventProcessor
---@field listeners NeotestEventListeners
local NeotestEventProcessor = {}

function NeotestEventProcessor:new()
  local events = {}
  local listeners = {}
  for _, event in pairs(NeotestEvents) do
    listeners[event] = {}
  end
  events.listeners = listeners
  setmetatable(events, self)
  self.__index = self
  return events
end

---@param event NeotestEvent
---@vararg any Arguments for the event
function NeotestEventProcessor:emit(event, ...)
  local args = { ... }
  async.run(function()
    logger.info("Emitting", event, "event")
    for name, listener in pairs(self.listeners[event] or {}) do
      logger.debug("Calling listener", name, "for event", event)
      local success, err = pcall(listener, unpack(args))
      if not success then
        logger.error("Error during listener", name, "for event:", err)
      end
    end
  end)
end

---@return NeotestEventProcessor
function M.processor()
  return NeotestEventProcessor:new()
end

return M
