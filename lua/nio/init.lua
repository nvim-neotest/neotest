local nio = {}
local tasks = require("nio.tasks")
local control = require("nio.control")
local uv = require("nio.uv")
local tests = require("nio.tests")
local ui = require("nio.ui")
local lsp = require("nio.lsp")

---@toc_entry Neovim Asynchrnous IO Library
---@text
--- A library for asynchronous IO in Neovim. It is inspired by the asyncio
--- library in Python. The library focuses on providing both common asynchronous
--- primitives and asynchronous APIs for Neovim's core.
---@class nio
nio = {}

nio.control = control
nio.uv = uv
nio.ui = ui
nio.tests = tests
nio.tasks = tasks
nio.lsp = lsp

--- Run a function in an async context. This is the entrypoint to all async
--- functionality.
--- ```lua
---   local nio = require("nio")
---   nio.run(function()
---     nio.sleep(10)
---     print("Hello world")
---   end)
--- ```
---@param func function
---@param cb? fun(success: boolean,...) Callback to invoke when the task is complete. If success is false then the parameters will be an error message and a traceback of the error, otherwise it will be the result of the async function.
---@return nio.tasks.Task
function nio.run(func, cb)
  return tasks.run(func, cb)
end

--- Creates an async function with a callback style function.
--- ```lua
---   local nio = require("nio")
---   local sleep = nio.wrap(function(ms, cb)
---     vim.defer_fn(cb, ms)
---   end, 2)
---
---   nio.run(function()
---     sleep(10)
---     print("Slept for 10ms")
---   end)
--- ```
---@param func function A callback style function to be converted. The last argument must be the callback.
---@param argc integer The number of arguments of func. Must be included.
---@return function Returns an async function
function nio.wrap(func, argc)
  return tasks.wrap(func, argc)
end

--- Takes an async function and returns a function that can run in both async
--- and non async contexts. When running in an async context, the function can
--- return values, but when run in a non-async context, a Task object is
--- returned and an extra callback argument can be supplied to receive the
--- result, with the same signature as the callback for `nio.run`.
---
--- This is useful for APIs where users don't want to create async
--- contexts but which are still used in async contexts internally.
---@param func async fun(...)
---@param argc? integer The number of arguments of func. Must be included if there are arguments.
function nio.create(func, argc)
  return tasks.create(func, argc)
end

--- Run a collection of async functions concurrently and return when
--- all have finished.
--- If any of the functions fail, all pending tasks will be cancelled and the
--- error will be re-raised
---@async
---@param functions function[]
---@return any[] Results of all functions
function nio.gather(functions)
  local results = {}

  local done_event = control.event()

  local err
  local running = {}
  for i, func in ipairs(functions) do
    local task = tasks.run(func, function(success, ...)
      if not success then
        err = ...
        done_event.set()
      end
      results[#results + 1] = { i = i, success = success, result = ... }
      if #results == #functions then
        done_event.set()
      end
    end)
    running[#running + 1] = task
  end
  done_event.wait()
  if err then
    for _, task in ipairs(running) do
      task.cancel()
    end
    error(err)
  end
  local sorted = {}
  for _, result in ipairs(results) do
    sorted[result.i] = result.result
  end
  return sorted
end

--- Run a collection of async functions concurrently and return the result of
--- the first to finish.
---@async
---@param functions function[]
---@return any
function nio.first(functions)
  local running_tasks = {}
  local event = control.event()
  local failed, result

  for _, func in ipairs(functions) do
    local task = tasks.run(func, function(success, ...)
      if event.is_set() then
        return
      end
      failed = not success
      result = { ... }
      event.set()
    end)
    table.insert(running_tasks, task)
  end
  event.wait()
  for _, task in ipairs(running_tasks) do
    task.cancel()
  end
  if failed then
    error(unpack(result))
  end
  return unpack(result)
end

local async_defer = nio.wrap(function(time, cb)
  assert(cb, "Cannot call sleep from non-async context")
  vim.defer_fn(cb, time)
end, 2)

--- Suspend the current task for given time.
---@param ms number Time in milliseconds
function nio.sleep(ms)
  async_defer(ms)
end

local wrapped_schedule = nio.wrap(vim.schedule, 1)

--- Yields to the Neovim scheduler to be able to call the API.
---@async
function nio.scheduler()
  wrapped_schedule()
end

---@nodoc
local function proxy_vim(prop)
  return setmetatable({}, {
    __index = function(_, k)
      return function(...)
        -- if we are in a fast event await the scheduler
        if vim.in_fast_event() then
          nio.scheduler()
        end

        return vim[prop][k](...)
      end
    end,
  })
end

--- Safely proxies calls to the vim.api module while in an async context.
nio.api = proxy_vim("api")
--- Safely proxies calls to the vim.fn module while in an async context.
nio.fn = proxy_vim("fn")

-- For type checking
if false then
  nio.api = vim.api
  nio.fn = vim.fn
end

return nio
