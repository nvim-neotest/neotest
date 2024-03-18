local tasks = require("nio.tasks")

local nio = {}

---@text
--- Async versions of plenary's test functions.
---@class nio.tests
---@field it fun(name: string, async_fun: fun())
---@field before_each fun(async_fun: fun())
---@field after_each fun(async_fun: fun())
nio.tests = {}

local with_timeout = function(func, timeout)
  local success, err, results
  return function()
    local task = tasks.run(func, function(success_, ...)
      success = success_
      if not success_ then
        err = ...
      else
        results = { ... }
      end
    end)

    vim.wait(timeout or 2000, function()
      return success ~= nil
    end, 20, false)

    if success == nil then
      error(string.format("Test task timed out\n%s", task.trace()))
    elseif not success then
      error(string.format("Test task failed with message:\n%s", err))
    end
    return unpack(results)
  end
end

local mt = {
  __index = function(_table, key)
    -- Hook functions from busted are only available within scope when the
    -- test is defined, not when it is run, so we need to capture them
    -- dynamically here.
    local hook = getfenv(2)[key]
    if not hook then
      return nil
    end

    if key == "it" then
      return function(name, async_func)
        hook(name, with_timeout(async_func, tonumber(vim.env.PLENARY_TEST_TIMEOUT)))
      end
    elseif key == "before_each" or key == "after_each" then
      return function(async_func)
        hook(with_timeout(async_func))
      end
    end
  end,
}

setmetatable(nio.tests, mt)

---Run the given function, applied to the remaining arguments, in an
---asynchronous context.  The return value (or values) is the return value of
---the asynchronous function.
---@param async_func function  Function to execute
---@param ... any  Arguments to `async_func`
---@return any ...  Return values of `async_func`
nio.tests.with_async_context = function(async_func, ...)
  local args = { ... }
  local thunk = function()
    return async_func(unpack(args))
  end
  local result = with_timeout(thunk, tonumber(vim.env.PLENARY_TEST_TIMEOUT))()
  return result
end

return nio.tests
