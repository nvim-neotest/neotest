local nio = require("nio")
local logger = require("neotest.logging")
local neotest = {}

--- Accumulates provided data and stores it, while sending to consumers.
--- Allows consuming all data ever pushed while subscribing at any point in time.
---@class neotest.FanoutAccum
---@field consumers fun(data: T)[]
---@field data? T
---@field accum fun(prev: T, new: any): T A function to combine previous data and new data
---@field semaphore nio.control.Semaphore
neotest.FanoutAccum = {}

---@generic T
---@param accum fun(prev: T, new: any): T
---@param init T
---@return neotest.FanoutAccum
function neotest.FanoutAccum:new(accum, init)
  self.__index = self
  return setmetatable({
    data = init,
    accum = accum,
    consumers = {},
    semaphore = nio.control.semaphore(1),
  }, self)
end

---@param cb fun(data: T): boolean|nil
function neotest.FanoutAccum:subscribe(cb)
  self.consumers[#self.consumers + 1] = cb
  if self.data then
    xpcall(cb, function(msg)
      logger.error("Error in fanout accumulator callback: " .. debug.traceback(msg))
    end, self.data)
  end
  return function()
    for i, consumer in ipairs(self.consumers) do
      if consumer == cb then
        table.remove(self.consumers, i)
        break
      end
    end
  end
end

---@async
---@param data T
function neotest.FanoutAccum:push(data)
  self.semaphore.with(function()
    self.data = self.accum(self.data, data)
    for _, cb in ipairs(self.consumers) do
      cb(data)
    end
  end)
end

---@private
return function(accum, init)
  return neotest.FanoutAccum:new(accum, init)
end
