local async = require("plenary.async")

local M = {}

---@async
---@return integer
function M.run(command, args)
  args = args or {}
  local stdin = vim.loop.new_pipe()
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local result_code = async.wrap(vim.loop.spawn, 3)(command[1], {
    stdio = { stdin, stdout, stderr },
    detached = false,
    args = #command > 1 and vim.list_slice(command, 2, #command) or nil,
  })
  stdin:close()
  stdout:close()
  stderr:close()
  if args.on_stdout then
    stdout:read_start(args.on_stdout)
  end
  if args.on_stderr then
    stderr:read_start(args.on_stderr)
  end
  return result_code
end

return M
