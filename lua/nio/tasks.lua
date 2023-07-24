local nio = {}
local logger = require("nio.logger")

---@class nio.tasks
nio.tasks = {}

---@type table<thread, nio.tasks.Task>
---@nodoc
local tasks = {}
---@type table<nio.tasks.Task, nio.tasks.Task[]>
---@nodoc
local child_tasks = {}

-- Coroutine.running() was changed between Lua 5.1 and 5.2:
-- - 5.1: Returns the running coroutine, or nil when called by the main thread.
-- - 5.2: Returns the running coroutine plus a boolean, true when the running coroutine is the main one.
-- For LuaJIT, 5.2 behaviour is enabled with LUAJIT_ENABLE_LUA52COMPAT

---@nodoc
local function current_non_main_co()
  local data = { coroutine.running() }

  if select("#", unpack(data)) == 2 then
    local co, is_main = unpack(data)
    if is_main then
      return nil
    end
    return co
  end

  return unpack(data)
end

---@text
--- Tasks represent a top level running asynchronous function
--- Only one task is ever executing at any time.
---@class nio.tasks.Task
---@field parent? nio.tasks.Task Parent task
---@field cancel fun(): nil Cancels the task
---@field trace fun(): string Get the stack trace of the task
---@field wait async function Wait for the task to finish, returning any result

---@class nio.tasks.TaskError
---@field message string
---@field traceback? string

local format_error = function(message, traceback)
  if not traceback then
    return string.format("The coroutine failed with this message: %s", message)
  end
  return string.format(
    "The coroutine failed with this message: %s\n%s",
    vim.startswith(traceback, message) and "" or ("\n" .. message),
    traceback
  )
end

---@return nio.tasks.Task
---@nodoc
function nio.tasks.run(func, cb)
  local co = coroutine.create(func)
  local cancelled = false
  local task = { parent = nio.tasks.current_task() }
  if task.parent then
    child_tasks[task.parent] = child_tasks[task.parent] or {}
    table.insert(child_tasks[task.parent], task)
  end
  local future = require("nio").control.future()

  function task.cancel()
    if coroutine.status(co) == "dead" then
      return
    end
    for _, child in pairs(child_tasks[task] or {}) do
      child.cancel()
    end
    cancelled = true
  end

  function task.trace()
    return debug.traceback(co)
  end

  function task.wait()
    return future.wait()
  end

  local function close_task(result, err)
    tasks[co] = nil
    if err then
      future.set_error(err)
      if cb then
        cb(false, err)
      elseif not cancelled then
        error("Async task failed without callback: " .. err)
      end
    else
      future.set(unpack(result))
      if cb then
        cb(true, unpack(result))
      end
    end
  end

  tasks[co] = task

  local function step(...)
    if cancelled then
      close_task(nil, format_error("Task was cancelled"))
      return
    end

    local yielded = { coroutine.resume(co, ...) }
    local success = yielded[1]

    if not success then
      close_task(nil, format_error(yielded[2], debug.traceback(co)))
      return
    end

    if coroutine.status(co) == "dead" then
      close_task({ unpack(yielded, 2, table.maxn(yielded)) })
      return
    end

    local _, nargs, err_or_fn = unpack(yielded)

    if type(err_or_fn) ~= "function" then
      error(
        ("Async internal error: expected function, got %s\nContext: %s\n%s"):format(
          type(err_or_fn),
          vim.inspect(yielded),
          debug.traceback(co)
        )
      )
    end

    local args = { select(4, unpack(yielded)) }

    args[nargs] = step

    err_or_fn(unpack(args, 1, nargs))
  end

  step()
  return task
end

---@param func function
---@param argc? number
---@return function
function nio.tasks.create(func, argc)
  vim.validate({
    func = { func, "function" },
    argc = { argc, "number", true },
  })
  argc = argc or 0
  return function(...)
    if current_non_main_co() then
      return func(...)
    end
    local args = { ... }
    local callback
    if #args > argc then
      callback = table.remove(args)
    end
    return nio.tasks.run(function()
      func(unpack(args))
    end, callback)
  end
end

---@package
---@nodoc
function nio.tasks.wrap(func, argc)
  vim.validate({ func = { func, "function" }, argc = { argc, "number" } })
  local protected = function(...)
    local args = { ... }
    local cb = args[argc]
    args[argc] = function(...)
      cb(true, ...)
    end
    xpcall(func, function(err)
      cb(false, err, debug.traceback())
    end, unpack(args, 1, argc))
  end

  return function(...)
    if not current_non_main_co() then
      return func(...)
    end

    local ret = { coroutine.yield(argc, protected, ...) }
    local success = ret[1]
    if not success then
      error(("Wrapped function failed: %s\n%s"):format(ret[2], ret[3]))
    end
    return unpack(ret, 2, table.maxn(ret))
  end
end

--- Get the current running task
---@return nio.tasks.Task|nil
function nio.tasks.current_task()
  local co = current_non_main_co()
  if not co then
    return nil
  end
  return tasks[co]
end

return nio.tasks
