local uv = vim.loop
local M = {}

--- Find all files under the given directory.
--- Does not search hidden directories.
---@async
---@param dir_path string
---@return string[] @Absolute paths of all files within directories to search
function M.find(dir_path)
  local sep = require("neotest.lib").files.sep
  local dirs_to_scan = { dir_path }

  local paths = {}
  local dir, dir_handle
  while dir_handle or #dirs_to_scan > 0 do
    if not dir_handle then
      dir = table.remove(dirs_to_scan, 1)
      dir_handle = uv.fs_scandir(dir)
    end

    local next_path, path_type = uv.fs_scandir_next(dir_handle)

    if not next_path then
      dir_handle = nil
    elseif path_type == "directory" and next_path:sub(1, 1) ~= "." then
      local i = #dirs_to_scan + 1
      dirs_to_scan[i] = dir .. sep .. next_path
    elseif path_type == "file" then
      paths[#paths + 1] = dir .. sep .. next_path
    end
  end
  return paths
end

return M
