local async = require("neotest.async")
local logger = require("neotest.logging")
local M = {}

-- Taken from telescope find_files
local function get_find_command(search_dirs)
  local find_command
  if not find_command then
    if 1 == async.fn.executable("fd") then
      find_command = { "fd", "--type", "f" }
      table.insert(find_command, ".")
      for _, v in pairs(search_dirs) do
        table.insert(find_command, v)
      end
    elseif 1 == async.fn.executable("fdfind") then
      find_command = { "fdfind", "--type", "f" }
      table.insert(find_command, ".")
      for _, v in pairs(search_dirs) do
        table.insert(find_command, v)
      end
    elseif 1 == async.fn.executable("rg") then
      find_command = { "rg", "--files" }
      for _, v in pairs(search_dirs) do
        table.insert(find_command, v)
      end
    elseif 1 == async.fn.executable("find") and async.fn.has("win32") == 0 then
      find_command = { "find", "-type", "f" }
      for _, v in pairs(search_dirs) do
        table.insert(find_command, 2, v)
      end
    end
  end
  return find_command
end

---@async
---@param search_dirs? string[] directories to search, defaults to current directory
---@return string[] @Absolute paths of all files within directories to search
function M.find(search_dirs)
  local find_command = get_find_command(search_dirs or { async.api.nvim_eval("getcwd()") })
  local finish_cond = async.control.Condvar.new()
  local stdin = vim.loop.new_pipe()
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local result_code
  logger.debug("Searching for files using command ", find_command)
  vim.loop.spawn(find_command[1], {
    stdio = { stdin, stdout, stderr },
    detached = true,
    args = #find_command > 1 and vim.list_slice(find_command, 2, #find_command) or nil,
    hide = true,
  }, function(code, _)
    result_code = code
    stdin:close()
    stdout:close()
    stderr:close()
    finish_cond:notify_all()
  end)
  local files_data = {}
  stdout:read_start(function(err, data)
    if err then
      logger.error(err)
      return
    end
    table.insert(files_data, data)
  end)
  stderr:read_start(function(err, data)
    if err or data then
      logger.error(err or data)
    end
  end)
  finish_cond:wait()
  logger.debug("Searching for files finished")
  if result_code > 0 then
    logger.error("Error while finding files")
    return {}
  end
  local files = vim.split(table.concat(files_data, ""), "\n", { plain = true, trimempty = true })
  return files
end

return M
