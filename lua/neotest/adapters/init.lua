local logger = require("neotest.logging")
local config = require("neotest.config")
local nio = require("nio")
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
  logger.info("Found", #adapters, "adapters for directory", cwd)
  logger.debug("Adapters:", adapters)
  return adapters
end

function AdapterGroup:adapters_matching_open_bufs(existing_roots)
  local function is_under_roots(path)
    for _, root in ipairs(existing_roots) do
      if vim.startswith(path, root) then
        return true
      end
    end
    return false
  end

  local adapters = {}
  local buffers = nio.api.nvim_list_bufs()

  local paths = lib.func_util.map(function(i, buf)
    local real
    if nio.api.nvim_buf_is_loaded(buf) then
      local path = nio.api.nvim_buf_get_name(buf)
      real = lib.files.path.real(path)
    end
    return i, real or false
  end, buffers)

  local matched_files = {}
  for _, path in ipairs(paths) do
    if path and not is_under_roots(path) then
      for _, adapter in ipairs(self:_path_adapters(path)) do
        if adapter.is_test_file(path) and not matched_files[path] then
          logger.info("Adapter", adapter.name, "matched buffer", path)
          matched_files[path] = true
          table.insert(adapters, adapter)
          break
        end
      end
    end
  end
  return adapters
end

function AdapterGroup:adapter_matching_path(path)
  for _, adapter in ipairs(self:_path_adapters(path)) do
    if adapter.is_test_file(path) then
      logger.info("Adapter", adapter.name, "matched path", path)
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
