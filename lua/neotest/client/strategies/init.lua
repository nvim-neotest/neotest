local lib = require("neotest.lib")
local nio = require("nio")
local logger = require("neotest.logging")

---@return neotest.Strategy
local get_strategy = function(name)
  return require("neotest.client.strategies." .. name)
end

---@class neotest.ProcessTracker
---@field _instances table<integer, neotest.Process>
---@field _process_semaphore nio.control.Semaphore
local ProcessTracker = {}

function ProcessTracker:new()
  -- Hack for Android devices, where cpu_info() returns nil
  local cpu_info = vim.loop.cpu_info() or {}
  local tracker = {
    _instances = {},
    _process_semaphore = nio.control.semaphore(#cpu_info + 4),
  }
  self.__index = self
  setmetatable(tracker, self)
  return tracker
end

---@async
---@param pos_id string
---@param spec neotest.RunSpec
---@param args table
---@param stream_processor async fun(data_iter: async fun(): string)
---@param context neotest.StrategyContext
---@return neotest.StrategyResult
function ProcessTracker:run(pos_id, spec, args, stream_processor, context)
  local strategy = self:_get_strategy(args)
  logger.info("Starting process", pos_id, "with strategy", args.strategy)
  logger.debug("Strategy spec", spec)
  local instance, code
  self._process_semaphore.with(function()
    instance = strategy(spec, context)
    if not instance then
      lib.notify("Adapter doesn't support chosen strategy.", vim.log.levels.ERROR)
      local output_path = nio.fn.tempname()
      assert(io.open(output_path, "w")):close()
      return { code = 1, output = output_path }
    end
    self._instances[pos_id] = instance
    if stream_processor then
      local iterator = lib.files.split_lines(instance.output_stream())
      nio.run(function()
        stream_processor(iterator)
      end)
    end
    code = instance.result()
  end)
  logger.info("Process for position", pos_id, "exited with code", code)
  local output = instance.output()
  logger.debug("Output of process ", output)
  self._instances[pos_id] = nil
  return { code = code, output = output }
end

function ProcessTracker:stop(pos_id)
  local instance = self._instances[pos_id]
  if not instance then
    return false
  end
  instance.stop()
  return true
end

---@return neotest.Strategy
function ProcessTracker:_get_strategy(args)
  if type(args.strategy) == "string" then
    return get_strategy(args.strategy)
  end
  return args.strategy
end

---@async
---@param pos_id string
function ProcessTracker:attach(pos_id)
  local instance = self._instances[pos_id]
  if not instance then
    return false
  end
  instance.attach()
  return true
end

function ProcessTracker:exists(proc_key)
  return self._instances[proc_key] ~= nil
end

return function()
  return ProcessTracker:new()
end
