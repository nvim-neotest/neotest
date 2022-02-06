local async = require("plenary.async")
local logger = require("neotest.logging")
local config = require("neotest.config")
local lib = require("neotest.lib")

local M = {}

function M.adapters_with_root_dir(cwd)
  local adapters = {}
  for _, adapter in ipairs(config.adapters) do
    local root = adapter.root(cwd)
    if root then
      table.insert(adapters, { adapter = adapter, root = root })
    end
  end
  return adapters
end

function M.adapters_matching_open_bufs()
  local adapters = {}
  local buffers = async.api.nvim_list_bufs()

  local paths = lib.func_util.map(function(i, buf)
    return i, async.fn.fnamemodify(async.fn.bufname(buf), ":p")
  end, buffers)

  for _, adapter in ipairs(config.adapters) do
    for _, path in ipairs(paths) do
      if adapter.is_test_file(path) then
        table.insert(adapters, adapter)
        break
      end
    end
  end
  return adapters
end

function M.get_file_adapter(file_path)
  for _, adapter in ipairs(config.adapters) do
    if adapter.is_test_file(file_path) then
      return adapter
    end
  end
end

return M
