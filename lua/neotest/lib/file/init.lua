local Path = require("plenary.path")
local async = require("plenary.async")
local filetype = require("plenary.filetype")
local fu = require("neotest.lib.func_util")
local types = require("neotest.types")
local FIFOQueue = types.FIFOQueue
local Tree = types.Tree

local M = {}

---@param file_path string
---@return string
function M.read(file_path)
  local open_err, file_fd = async.uv.fs_open(file_path, "r", 438)
  assert(not open_err, open_err)
  local stat_err, stat = async.uv.fs_fstat(file_fd)
  assert(not stat_err, stat_err)
  local read_err, data = async.uv.fs_read(file_fd, stat.size, 0)
  assert(not read_err, read_err)
  local close_err = async.uv.fs_close(file_fd)
  assert(not close_err, close_err)
  return data
end

function M.read_lines(file_path)
  local data = M.read(file_path)
  local lines = {}
  for line in vim.gsplit(data, "[\r]?\n", false) do
    lines[#lines + 1] = line
  end
  return lines
end

function M.exists(path)
  local ok, err, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

function M.is_dir(path)
  if path == "/" then
    return true
  end
  return M.exists(path .. M.sep)
end

M.find = require("neotest.lib.file.find").find

function M.parent(path)
  local elems = vim.split(path, M.sep, { plain = true })
  return table.concat(elems, M.sep, 1, #elems - 1)
end

M.sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

---@type fun(path: string): string
M.detect_filetype = fu.memoize(filetype.detect)

---@param files string[] List of files to include in directory tree, along with parents
---@return Tree
function M.parse_dir_from_files(root, files)
  local function parse_tree(dirs)
    ---@type NeotestPosition
    local parent = dirs:pop()
    if not parent then
      return nil
    end
    local function dir_contains(dir, child)
      return vim.startswith(child.path, dir.path)
    end
    local current_level = { parent }
    while true do
      local next_pos = dirs:peek()
      if not next_pos or not dir_contains(parent, next_pos) then
        return current_level
      end
      current_level[#current_level + 1] = parse_tree(dirs)
    end
  end

  ---@param paths table[]
  ---@return NeotestPosition[]
  local function paths_to_positions(paths)
    local positions = FIFOQueue()
    local sep = M.sep
    if root == "/" then
      root = ""
    end
    for _, path in ipairs(paths) do
      local path_elems = vim.split(path.path, sep, { plain = true, trimempty = true })
      local abs_path
      if path.path ~= "" then
        abs_path = root .. M.sep .. path.path
      else
        abs_path = root
      end
      positions:push({
        type = path.type,
        id = abs_path,
        path = abs_path,
        name = path_elems[#path_elems],
        range = nil,
      })
    end
    return positions
  end

  -- TODO: Clean this up
  local path_sep = M.sep
  local all_dir_elems = {}
  for _, file in ipairs(files) do
    local elems = vim.split(file:sub(#root + 1), path_sep, { trimempty = true })
    local cur_elems = {}
    while #elems > 0 do
      table.insert(cur_elems, table.remove(elems, 1))
      table.insert(
        all_dir_elems,
        { path = table.concat(cur_elems, path_sep), type = #elems > 0 and "dir" or "file" }
      )
    end
  end
  local paths = {}
  for _, elem in ipairs(all_dir_elems) do
    paths[elem.path] = elem
  end
  local sorted_paths = { { path = "", type = "dir" } }
  for _, elem in pairs(paths) do
    table.insert(sorted_paths, elem)
  end
  table.sort(sorted_paths, function(a, b)
    return a.path < b.path
  end)
  return Tree.from_list(parse_tree(paths_to_positions(sorted_paths)), function(pos)
    return pos.id
  end)
end

---@vararg string
---@return fun(path: string): string | nil
function M.match_root_pattern(...)
  local patterns = vim.tbl_flatten({ ... })
  return function(start_path)
    local potential_roots = vim.list_extend({ start_path }, Path:new(start_path):parents())
    for _, path in ipairs(potential_roots) do
      for _, pattern in ipairs(patterns) do
        for _, p in ipairs(async.fn.glob(Path:new(path, pattern).filename, true, true)) do
          if M.exists(p) then
            return path
          end
        end
      end
    end
  end
end

return M
