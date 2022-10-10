local async = require("neotest.async")
local uv = async.uv
local M = {}
local lib = require("neotest.lib")

local async_opendir = async.wrap(function(path, entries, cb)
  return vim.loop.fs_opendir(path, cb, entries)
end, 3)

--- Find all files under the given directory.
--- Does not search hidden directories.
---@async
---@param root string
---@return string[] @Absolute paths of all files within directories to search
function M.find(root, opts)
  opts = opts or {}
  local filter_dir = opts.filter_dir
  local sep = lib.files.sep
  local dirs_to_scan = {}

  local paths = {}
  local dir = ""
  local max_entries = 1000
  local err, dir_handle = async_opendir(root, max_entries)
  assert(not err, err)
  while dir_handle or #dirs_to_scan > 0 do
    if not dir_handle then
      dir = table.remove(dirs_to_scan, 1)
      err, dir_handle = async_opendir(dir, max_entries)
      assert(not err, err)
    end

    local iter_dir = function()
      local pending = {}
      return function()
        if #pending == 0 then
          err, pending = uv.fs_readdir(dir_handle)
          assert(not err, err)
          if not pending then
            uv.fs_closedir(dir_handle)
            dir_handle = nil
            return nil
          end
        end
        return table.remove(pending)
      end
    end

    for entry in iter_dir() do
      local name, path_type = entry.name, entry.type
      local rel_path = name and (dir == "" and name or (dir .. sep .. name))
      if
        path_type == "directory"
        and name:sub(1, 1) ~= "."
        and (not filter_dir or filter_dir(name, rel_path, root))
      then
        dirs_to_scan[#dirs_to_scan + 1] = rel_path
      elseif path_type == "file" then
        paths[#paths + 1] = (root .. sep .. rel_path)
      end
    end
  end
  return paths
end

return M
