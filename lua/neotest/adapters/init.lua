local async = require("neotest.async")
local lib = require("neotest.lib")

---@class neotest.AdapterGroup
---@field adapters neotest.Adapter[]
local AdapterGroup = {}

function AdapterGroup:adapters_with_root_dir(cwd)
  local adapters = {}
  for _, adapter in ipairs(self.adapters) do
    local root = adapter.root(cwd)
    if root then
      table.insert(adapters, { adapter = adapter, root = root })
    end
  end
  return adapters
end

function AdapterGroup:adapters_matching_open_bufs()
  local adapters = {}
  local buffers = async.api.nvim_list_bufs()

  local paths = lib.func_util.map(function(i, buf)
    return i, async.fn.fnamemodify(async.fn.bufname(buf), ":p")
  end, buffers)

  local matched_files = {}
  for _, adapter in ipairs(self.adapters) do
    for _, path in ipairs(paths) do
      if adapter.is_test_file(path) and not matched_files[path] then
        matched_files[path] = true
        table.insert(adapters, adapter)
        break
      end
    end
  end
  return adapters
end

function AdapterGroup:get_file_adapter(file_path)
  for _, adapter in ipairs(self.adapters) do
    if adapter.is_test_file(file_path) then
      return adapter
    end
  end
end

function AdapterGroup:new(adapters)
  local group = { adapters = adapters }
  self.__index = self
  setmetatable(group, self)
  return group
end

return function(adapters)
  return AdapterGroup:new(adapters)
end
