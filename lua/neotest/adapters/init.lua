local config = require("neotest.config")
local async = require("neotest.async")
local lib = require("neotest.lib")

---@class neotest.AdapterGroup
---@field adapters neotest.Adapter[]
local AdapterGroup = {}

function AdapterGroup:adapters_with_root_dir(cwd)
  local adapters = {}
  for _, adapter in ipairs(self:_path_adapters(cwd)) do
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
  for _, path in ipairs(paths) do
    for _, adapter in ipairs(self:_path_adapters(path)) do
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
  for _, adapter in ipairs(self:_path_adapters(file_path)) do
    if adapter.is_test_file(file_path) then
      return adapter
    end
  end
end

---@param path string
function AdapterGroup:_path_adapters(path)
  if vim.endswith(path, lib.files.sep) then
    path = path:sub(1, -2)
  end
  for root, project_config in pairs(config.projects) do
    if root == path or vim.startswith(path, root .. lib.files.sep) then
      return project_config.adapters
    end
  end
  return config.adapters
end

function AdapterGroup:new()
  local group = {}
  self.__index = self
  setmetatable(group, self)
  return group
end

return function()
  return AdapterGroup:new()
end
