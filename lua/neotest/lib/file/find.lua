local uv = vim.loop
local M = {}

--- Find all files under the given directory.
--- Does not search hidden directories.
---@async
---@param root string
---@return string[] @Absolute paths of all files within directories to search
function M.find(root, opts)
  opts = opts or {}
  local filter_dir = opts.filter_dir
  local sep = require("neotest.lib").files.sep
  local dirs_to_scan = {}

  local paths = {}
  local dir, dir_handle = "", uv.fs_scandir(root)
  while dir_handle or #dirs_to_scan > 0 do
    if not dir_handle then
      dir = table.remove(dirs_to_scan, 1)
      dir_handle = uv.fs_scandir(dir)
    end

    local name, path_type = uv.fs_scandir_next(dir_handle)
    local rel_path = name and (dir == "" and name or (dir .. sep .. name))

    if not name then
      dir_handle = nil
    elseif
      path_type == "directory"
      and name:sub(1, 1) ~= "."
      and (not filter_dir or filter_dir(name, rel_path, root))
    then
      dirs_to_scan[#dirs_to_scan + 1] = rel_path
    elseif path_type == "file" then
      paths[#paths + 1] = (root .. sep .. rel_path)
    end
  end
  return paths
end

return M
