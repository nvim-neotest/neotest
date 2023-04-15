local tasks = require("nio.tasks")

local nio = {}

---@text
--- Provides primitives for flow control in async functions
---@class nio.control
nio.control = {}

---@text
--- An event can signal to multiple listeners to resume execution
--- The event can be set from a non-async context.
---@class nio.control.Event
---@field set fun(max_woken?: integer): nil Set the event and signal to all (or limited number of) listeners that the event has occurred. If max_woken is provided and there are more listeners then the event is cleared immediately
---@field wait async fun(): nil Wait for the event to occur, returning immediately if
--- already set
---@field clear fun(): nil Clear the event
---@field is_set fun(): boolean Returns true if the event is set

--- Create a new event
---@return nio.control.Event
function nio.control.event()
  local waiters = {}
  local is_set = false
  return {
    is_set = function()
      return is_set
    end,
    set = function(max_woken)
      if is_set then
        return
      end
      is_set = true
      local waiters_to_notify = {}
      max_woken = max_woken or #waiters
      while #waiters > 0 and #waiters_to_notify < max_woken do
        waiters_to_notify[#waiters_to_notify + 1] = table.remove(waiters)
      end
      if #waiters > 0 then
        is_set = false
      end
      for _, waiter in ipairs(waiters_to_notify) do
        waiter()
      end
    end,
    wait = tasks.wrap(function(callback)
      if is_set then
        callback()
      else
        waiters[#waiters + 1] = callback
      end
    end, 1),
    clear = function()
      is_set = false
    end,
  }
end

---@text
--- An future represents a value that will be available at some point and can be awaited upon.
--- The future result can be set from a non-async context.
---@class nio.control.Future
---@field set fun(value): nil Set the future value and wake all waiters.
---@field set_error fun(message): nil Set the error for this future to raise to
---the waiters
---@field wait async fun(): any Wait for the value to be set, returning immediately if already set

--- Create a new future
---@return nio.control.Future
function nio.control.future()
  local waiters = {}
  local result, err, is_set
  local wait = tasks.wrap(function(callback)
    if is_set then
      callback()
    else
      waiters[#waiters + 1] = callback
    end
  end, 1)
  local wake = function()
    for _, waiter in ipairs(waiters) do
      waiter()
    end
  end
  return {
    set = function(value)
      if is_set then
        error("Future already set")
      end
      result = value
      is_set = true
      wake()
    end,
    set_error = function(message)
      if is_set then
        error("Future already set")
      end
      err = message
      is_set = true
      wake()
    end,
    wait = function()
      if not is_set then
        wait()
      end

      if err then
        error(err)
      end
      return result
    end,
  }
end

---@text
--- A FIFO queue with async support.
---@class nio.control.Queue
---@field size fun(): number Returns the number of items in the queue
---@field max_size fun(): number|nil Returns the maximum number of items in the queue
---@field get async fun(): any Get a value from the queue, blocking if the queue is empty
---@field get_nowait fun(): any Get a value from the queue, erroring if queue is empty.
---@field put async fun(value: any): nil Put a value into the queue
---@field put_nowait fun(value: any): nil Put a value into the queue, erroring if queue is full.

--- Create a new queue
---@param max_size? integer The maximum number of items in the queue, defaults to no limit
---@return nio.control.Queue
function nio.control.queue(max_size)
  local items = {}
  local left_i = 0
  local right_i = 0
  local non_empty = nio.control.event()
  local non_full = nio.control.event()
  non_full.set()

  local queue = {}

  function queue.size()
    return right_i - left_i
  end

  function queue.max_size()
    return max_size
  end

  function queue.put(value)
    non_full.wait()
    queue.put_nowait(value)
  end

  function queue.get()
    non_empty.wait()
    return queue.get_nowait()
  end

  function queue.get_nowait()
    if queue.size() == 0 then
      error("Queue is empty")
    end
    left_i = left_i + 1
    local item = items[left_i]
    items[left_i] = nil
    if left_i == right_i then
      non_empty.clear()
    end
    non_full.set(1)
    return item
  end

  function queue.put_nowait(value)
    if queue.size() == max_size then
      error("Queue is full")
    end
    right_i = right_i + 1
    items[right_i] = value
    non_empty.set(1)
    if queue.size() == max_size then
      non_full.clear()
    end
  end

  return queue
end

---@text
--- An async semaphore that allows up to a given number of acquisitions.
---@class nio.control.Semaphore
---@field with async fun(callback: fun(): nil): nil Run the callback with the semaphore acquired

--- Create a new semaphore
---@param value integer The number of allowed concurrent acquisitions
function nio.control.semaphore(value)
  value = value or 1
  local released_event = nio.control.event()
  released_event.set()
  return {
    with = function(cb)
      released_event.wait()
      value = value - 1
      assert(value >= 0, "Semaphore value is negative")
      if value == 0 then
        released_event.clear()
      end
      local success, err = pcall(cb)
      value = value + 1
      released_event.set(1)
      if not success then
        error(err)
      end
    end,
  }
end

return nio.control
