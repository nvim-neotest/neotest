local nio = require("nio")

local neotest = { lib = {} }
---@toc_entry Library: Processes
---@text
--- Utilities to run external processes easily.
--- More complex use cases should use the lower level jobstart or vim.loop.spawn
---@class neotest.lib.process
neotest.lib.process = {}

---@class neotest.lib.process.RunArgs
---@field stdout boolean Read stdout
---@field stderr boolean Read stderr

---@class neotest.lib.process.RunResult
---@field stdout? string
---@field stderr? string

--- Runs a process using libuv. This is designed for a simple, quick async
--- alternative to io.popen and so will wait until the process exits to read
--- the stdout/stderr. Do not use this for long running jobs or for large
--- outputs. Use vim.jobstart instead.
---@async
---@param command string[]
---@param args? neotest.lib.process.RunArgs
---@return integer,neotest.lib.process.RunResult Exit code and table containing stdout/stderr keys if requested
function neotest.lib.process.run(command, args)
  args = args or {}
  local stdin = vim.loop.new_pipe()
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local exit_future = nio.control.future()

  local handle, pid = vim.loop.spawn(command[1], {
    stdio = { stdin, stdout, stderr },
    detached = false,
    args = #command > 1 and vim.list_slice(command, 2, #command) or nil,
  }, exit_future.set)

  if not handle then
    error(pid)
  end

  local stdout_data, stderr_data
  if args.stdout then
    stdout_data = ""
    local read_future = nio.control.future()
    stdout:read_start(function(err, data)
      assert(not err, err)
      if data then
        stdout_data = stdout_data .. data
      else
        read_future.set()
      end
    end)
    read_future.wait()
  end
  if args.stderr then
    stderr_data = ""
    local read_future = nio.control.future()
    stderr:read_start(function(err, data)
      assert(not err, err)
      if data then
        stderr_data = stderr_data .. data
      else
        read_future.set()
      end
    end)
    read_future.wait()
  end

  local result_code = exit_future.wait()
  handle:close()

  stdin:close()
  stdout:close()
  stderr:close()
  return result_code, {
    stdout = stdout_data,
    stderr = stderr_data,
  }
end

return neotest.lib.process
