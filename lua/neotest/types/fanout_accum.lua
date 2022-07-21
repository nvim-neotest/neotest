---Accumulates provided data and stores it, while sending to consumers.
---Allows consuming all data ever pushed while subscribing at any point in time.
---@class FanoutAccum
---@field consumers fun(data: T)[]
---@field data T | nil
---@field accum fun(prev: T, new: any): T A function to combine previous data and new data
local FanoutAccum = {}

---@generic T
---@param accum fun(prev: T, new: any): T
---@param init T
---@return FanoutAccum
function FanoutAccum:new(accum, init)
  self.__index = self
  return setmetatable({
    data = init,
    accum = accum,
    consumers = {},
  }, self)
end

function FanoutAccum:subscribe(cb)
  self.consumers[#self.consumers + 1] = cb
  if self.data then
    cb(self.data)
  end
end

function FanoutAccum:push(data)
  self.data = self.accum(self.data, data)
  for _, cb in ipairs(self.consumers) do
    cb(data)
  end
end

return function(accum, init)
  return FanoutAccum:new(accum, init)
end
