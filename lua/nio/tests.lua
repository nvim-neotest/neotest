local tasks = require("nio.tasks")

local nio = {}

---@text
--- Async versions of plenary's test functions.
---@class nio.tests
nio.tests = {}

local with_timeout = function(func, timeout)
  local success, err
  return function()
    local task = tasks.run(func, function(success_, err_)
      success = success_
      if not success_ then
        err = err_
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
  end
end

---@param name string
---@param async_func function
nio.tests.it = function(name, async_func)
  it(name, with_timeout(async_func, tonumber(vim.env.PLENARY_TEST_TIMEOUT)))
end

---@param async_func function
nio.tests.before_each = function(async_func)
  before_each(with_timeout(async_func))
end

---@param async_func function
nio.tests.after_each = function(async_func)
  after_each(with_timeout(async_func))
end

return nio.tests
