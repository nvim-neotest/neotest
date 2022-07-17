local lib = require("neotest.lib")
local async = require("neotest.async")
local logger = require("neotest.logging")
local fu = lib.func_util

---@return neotest.Strategy
local get_strategy = fu.memoize(function(name)
  return require("neotest.client.strategies." .. name)
end)

---@class neotest.ProcessTracker
---@field _instances table<integer, neotest.Process>
local ProcessTracker = {}

function ProcessTracker:new()
  local tracker = {
    _instances = {},
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
---@return neotest.StrategyResult
function ProcessTracker:run(pos_id, spec, args, stream_processor)
  local strategy = self:_get_strategy(args)
  logger.info("Starting process", pos_id, "with strategy", args.strategy)
  logger.debug("Strategy spec", spec)
  local instance = strategy(spec)
  if not instance then
    lib.notify("Adapter doesn't support chosen strategy.", vim.log.levels.ERROR)
    local output_path = async.fn.tempname()
    assert(io.open(output_path, "w")):close()
    return { code = 1, output = output_path }
  end
  self._instances[pos_id] = instance
  if stream_processor then
    local iterator = lib.files.split_lines(instance.output_stream())
    async.run(function()
      stream_processor(iterator)
    end)
  end
  local code = instance.result()
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
