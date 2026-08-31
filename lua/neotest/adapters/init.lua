local logger = require("neotest.logging")
local config = require("neotest.config")
local nio = require("nio")
local lib = require("neotest.lib")

---@class neotest.AdapterGroup
---@field adapters neotest.Adapter[]
local AdapterGroup = {}

function AdapterGroup:adapters_with_root_dir(cwd)
  cwd = lib.files.path.normalize(cwd)
  local adapters = {}
  for _, adapter in ipairs(self:_path_adapters(cwd)) do
    local root = adapter.root and adapter.root(cwd)
    if root then
      root = lib.files.path.normalize(root)
      table.insert(adapters, { adapter = adapter, root = root })
    end
  end
  logger.info("Found", #adapters, "adapters for directory", cwd)
  logger.debug("Adapters:", adapters)
  return adapters
end

function AdapterGroup:adapters_matching_open_bufs(existing_roots)
  local roots = {}
  for _, r in ipairs(existing_roots or {}) do
    table.insert(roots, lib.files.path.normalize(r))
  end

  local function is_under_roots(path)
    local norm_path = lib.files.path.normalize(path)
    for _, root in ipairs(roots) do
      if vim.startswith(norm_path, root) then
        return true
      end
    end
    return false
  end

  local adapters_with_roots = {}
  local buffers = nio.api.nvim_list_bufs()

  local paths = lib.func_util.map(function(i, buf)
    local real
    if nio.api.nvim_buf_is_loaded(buf) then
      local path = nio.api.nvim_buf_get_name(buf)
      real = lib.files.path.real(path) or lib.files.path.normalize(path)
    end
    return i, real or false
  end, buffers)

  local matched_files = {}
  for _, path in ipairs(paths) do
    if path and not is_under_roots(path) then
      for _, adapter in ipairs(self:_path_adapters(path)) do
        if adapter.is_test_file and adapter.is_test_file(path) and not matched_files[path] then
          logger.info("Adapter", adapter.name, "matched buffer", path)
          matched_files[path] = true
          local parent_dir = lib.files.parent(path)
          local root = (adapter.root and adapter.root(parent_dir)) or parent_dir
          root = lib.files.path.normalize(root)
          table.insert(adapters_with_roots, { adapter = adapter, root = root })
          table.insert(roots, root)
          break
        end
      end
    end
  end
  return adapters_with_roots
end

function AdapterGroup:adapter_matching_path(path)
  path = lib.files.path.normalize(path)
  for _, adapter in ipairs(self:_path_adapters(path)) do
    if adapter.is_test_file and adapter.is_test_file(path) then
      logger.info("Adapter", adapter.name, "matched path", path)
      return adapter
    end
  end
end

---@param path string
function AdapterGroup:_path_adapters(path)
  path = lib.files.path.normalize(path)
  if vim.endswith(path, lib.files.sep) then
    path = path:sub(1, -2)
  end
  for root, project_config in pairs(config.projects) do
    local norm_root = lib.files.path.normalize(root)
    if norm_root == path or vim.startswith(path, norm_root .. lib.files.sep) then
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
