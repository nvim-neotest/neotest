local config = require("neotest.config")
local loggers = {}

local log_date_format = "%FT%H:%M:%SZ%z"

---@class neotest.Logger
---@field trace function
---@field debug function
---@field info function
---@field warn function
---@field error function
local Logger = {}

---@return neotest.Logger
function Logger.new(filename, opts)
  opts = opts or {}
  local logger = loggers[filename]
  if logger then
    return logger
  end
  logger = {}
  setmetatable(logger, { __index = Logger })
  loggers[filename] = logger
  local path_sep = (function()
    if jit then
      local os = string.lower(jit.os)
      if os == "linux" or os == "osx" or os == "bsd" then
        return "/"
      else
        return "\\"
      end
    else
      return package.config:sub(1, 1)
    end
  end)()

  local function path_join(...)
    return table.concat(vim.tbl_flatten({ ... }), path_sep)
  end

  logger._level = opts.level or config.log_level
  local ok, logpath = pcall(vim.fn.stdpath, "log")
  if not ok then
    logpath = vim.fn.stdpath("cache")
  end
  logger._filename = path_join(logpath, filename .. ".log")

  vim.fn.mkdir(logpath, "p")
  local logfile = assert(io.open(logger._filename, "a+"))
  for level, levelnr in pairs(vim.log.levels) do
    logger[level:lower()] = function(...)
      local argc = select("#", ...)
      if levelnr < logger._level then
        return false
      end
      if argc == 0 then
        return true
      end
      local info = debug.getinfo(2, "Sl")
      local fileinfo = string.format("%s:%s", info.short_src, info.currentline)
      local parts = {
        table.concat({ level, "|", os.date(log_date_format), "|", fileinfo, "|" }, " "),
      }
      for i = 1, argc do
        local arg = select(i, ...)
        if arg == nil then
          table.insert(parts, "<nil>")
        elseif type(arg) == "string" then
          table.insert(parts, arg)
        elseif type(arg) == "table" and arg.__tostring then
          table.insert(parts, arg.__tostring(arg))
        else
          table.insert(parts, vim.inspect(arg))
        end
      end
      logfile:write(table.concat(parts, " "), "\n")
      logfile:flush()
    end
  end
  logfile:write("\n")
  return logger
end

function Logger:set_level(level)
  self._level = assert(
    type(level) == "number" and level or vim.log.levels[tostring(level):upper()],
    string.format("Log level must be one of (trace, debug, info, warn, error), got: %q", level)
  )
end

function Logger:get_filename()
  return self._filename
end

return Logger.new("neotest")
