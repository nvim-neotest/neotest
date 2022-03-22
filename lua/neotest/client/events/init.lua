local async = require("neotest.async")
local logger = require("neotest.logging")

local M = {}

---@alias neotest.Event "discover_positions" | "run" | "results" | "test_file_focused" | "test_focused"
---@class neotest.Events
local NeotestEvents = {
  DISCOVER_POSITIONS = "discover_positions",
  RUN = "run",
  RESULTS = "results",
  TEST_FILE_FOCUSED = "test_file_focused",
  TEST_FOCUSED = "test_focused",
}

M.events = NeotestEvents

---@class neotest.InternalClientListeners
---@field discover_positions table<string, fun(adapter_id: integer, path: string, tree: neotest.Tree)>
---@field run table<string, fun(adapter_id: integer, position_ids: string[])>
---@field results table<string, fun(adapter_id: integer, results: table<string, neotest.Result>)>
---@field test_file_focused table<string,fun(file_path: string)>>
---@field test_focused table<string,fun(pos_id: string)>>

---@class neotest.EventProcessor
---@field listeners neotest.InternalClientListeners
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

---@param event neotest.Event
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

---@return neotest.EventProcessor
function M.processor()
  return NeotestEventProcessor:new()
end

return M
