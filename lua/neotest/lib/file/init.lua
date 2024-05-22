local logger = require("neotest.logging")
local Path = require("plenary.path")
local nio = require("nio")
local filetype = require("plenary.filetype")
local fu = require("neotest.lib.func_util")
local types = require("neotest.types")
local utils = require("neotest.utils")
local Tree = types.Tree

local neotest = { lib = {} }

---@toc_entry Library: Files
---@text
--- Helper functions for interacting with files
---@class neotest.lib.files
neotest.lib.files = {}

--- Read a file asynchronously
---@async
---@param file_path string
---@return string
function neotest.lib.files.read(file_path)
  logger.debug("Reading file: " .. file_path)
  local open_err, file_fd = nio.uv.fs_open(file_path, "r", 438)
  assert(not open_err, open_err)
  local stat_err, stat = nio.uv.fs_fstat(file_fd)
  assert(not stat_err, stat_err)
  local read_err, data = nio.uv.fs_read(file_fd, stat.size, 0)
  assert(not read_err, read_err)
  local close_err = nio.uv.fs_close(file_fd)
  assert(not close_err, close_err)
  return data
end

--- Write to a file asynchronously
---@param file_path string
---@param data string
function neotest.lib.files.write(file_path, data)
  logger.debug("Writing file: " .. file_path)
  local open_err, file_fd = nio.uv.fs_open(file_path, "w", 438)
  assert(not open_err, open_err)
  local write_err = nio.uv.fs_write(file_fd, data, 0)
  assert(not write_err, write_err)
  local close_err = nio.uv.fs_close(file_fd)
  assert(not close_err, close_err)
end

--- Read a file asynchronously, splitting the content into lines
---@async
---@param file_path string
---@return string[]
function neotest.lib.files.read_lines(file_path)
  local data = neotest.lib.files.read(file_path)
  return vim.split(data, "[\r]?\n", { trimempty = true })
end

--- Splits an async iterator of strings into lines. This is useful for data coming
--- from a process where the data can be split randomly
---@async
---@param data_iterator fun(): string
---@return fun(): string[]
function neotest.lib.files.split_lines(data_iterator)
  local queue = nio.control.queue()

  local producer = function()
    local orig = ""
    local pending_data = nil
    for data in data_iterator do
      if data ~= "" then
        orig = orig .. data
        local ends_with_newline = vim.endswith(data, "\n")
        local next_lines = vim.split(data, "[\r]?\n", { trimempty = true })
        if pending_data then
          if vim.startswith(data, "\r\n") or vim.startswith(data, "\n") then
            table.insert(next_lines, 1, pending_data)
          else
            next_lines[1] = pending_data .. next_lines[1]
          end
          pending_data = nil
        end
        if not ends_with_newline then
          pending_data = table.remove(next_lines, #next_lines)
        end
        queue.put(next_lines)
      end
    end
  end

  nio.run(producer, function(success, err)
    if not success then
      logger.error("Error while splitting lines: " .. err)
    end
  end)

  return queue.get
end

--- Streams data from a file, watching for new data over time
--- Only works when data is exlusively added and not deleted from the file
--- Useful for watching a file which is written to by another process.
---@async
---@param file_path string
---@return fun(): string Iterator
---@return function Callback to stop streaming
function neotest.lib.files.stream(file_path)
  local queue = nio.control.queue()
  local read_semaphore = nio.control.semaphore(1)

  local open_err, file_fd = nio.uv.fs_open(file_path, "r", 438)
  assert(not open_err and file_fd, open_err)
  local data_read = 0

  local exit_future = nio.control.future()
  local read = function()
    read_semaphore.with(function()
      local stat_err, stat = nio.uv.fs_fstat(file_fd)
      assert(not stat_err and stat, stat_err)
      if data_read == stat.size then
        return
      end
      if data_read > stat.size then
        exit_future.set_error("Data deleted from file while streaming")
        error("Data deleted from file while streaming")
      end
      local read_err, data = nio.uv.fs_read(file_fd, stat.size - data_read, data_read)
      assert(not read_err, read_err)
      data_read = #data + data_read
      queue.put(data)
    end)
  end

  read()
  local event = vim.loop.new_fs_event()
  assert(event, "Failed to create fs event")
  event:start(file_path, {}, function(err, _, _)
    assert(not err)
    nio.run(read, function(success, stream_err)
      if not success then
        logger.error("Error while streaming file: " .. stream_err)
      end
    end)
  end)

  local function stop()
    exit_future.wait()
    event:stop()
    local close_err = nio.uv.fs_close(file_fd)
    assert(not close_err, close_err)
  end

  nio.run(stop, function(success, err)
    if not success then
      logger.error("Error while stopping file stream: " .. err)
    end
  end)

  return queue.get, exit_future.set
end

--- Stream data from a file over time, splitting the content into lines
---@param file_path string
---@return fun(): string[] Iterator
---@return fun() Callback to stop streaming
function neotest.lib.files.stream_lines(file_path)
  local stream, stop = neotest.lib.files.stream(file_path)
  return neotest.lib.files.split_lines(stream), stop
end

--- Check if a path exists
---@param path string
---@return boolean,string|nil
function neotest.lib.files.exists(path)
  local ok, err, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

--- Check if a path is a directory
---@param path string
---@return boolean
function neotest.lib.files.is_dir(path)
  return nio.fn.isdirectory(path) == 1
end

---@class neotest.lib.files.FindOptions
---@field filter_dir fun(name: string, rel_path: string, root: string): boolean Filter directories to be searched

--- Find all files under the given directory.
--- Does not search hidden directories.
---@async
---@param root string
---@param opts neotest.lib.files.FindOptions
---@return string[] @Absolute paths of all files within directories to search
neotest.lib.files.find = function(root, opts)
  return require("neotest.lib.file.find").find(root, opts)
end

--- Get the parent directory of a path
---@param path string
---@return string
function neotest.lib.files.parent(path)
  local elems = vim.split(path, neotest.lib.files.sep, { plain = true })
  return table.concat(elems, neotest.lib.files.sep, 1, #elems - 1)
end

--- Path separator for the current OS
---@type string
neotest.lib.files.sep = (function()
  local res
  if jit then
    local os = string.lower(jit.os)
    if os == "linux" or os == "osx" or os == "bsd" then
      res = "/"
    else
      res = "\\"
    end
  else
    res = package.config:sub(1, 1)
  end
  logger.debug("Path separator:", res)
  return res
end)()

---@nodoc
neotest.lib.files.path = {
  sep = neotest.lib.files.sep,
  exists = neotest.lib.files.exists,
  real = function(path)
    local normalized_path = nio.fn.fnamemodify(path, ":p")
    local exists = neotest.lib.files.exists(normalized_path)
    return exists and normalized_path or nil, exists
  end,
}

local memoized_detect = fu.memoize(filetype.detect)

--- Detect the filetype of a file by checking the name, extensions, shebang or
--- modeline. This is a memoized wrapper around plenary's filetype detection.
---@param path string
---@return string
function neotest.lib.files.detect_filetype(path)
  return memoized_detect(path)
end

--- Parse a sorted list of file paths into a position tree
---@param files string[] List of files to include in directory tree, along with parents
---@return neotest.Tree
function neotest.lib.files.parse_dir_from_files(root, files)
  local function parse_tree(dirs)
    ---@type neotest.Position
    local parent = table.remove(dirs, 1)
    if not parent then
      return nil
    end
    local function dir_contains(dir, child)
      return vim.startswith(child.path, dir.path .. neotest.lib.files.sep)
    end

    local current_level = { parent }
    while true do
      local next_pos = dirs[1]
      if not next_pos or not dir_contains(parent, next_pos) then
        return current_level
      end
      current_level[#current_level + 1] = parse_tree(dirs)
    end
  end

  ---@param paths table[]
  ---@return neotest.Position[]
  local function paths_to_positions(paths)
    local positions = {}
    local sep = neotest.lib.files.sep
    if root == "/" then
      root = ""
    end
    for _, path in ipairs(paths) do
      local abs_path
      if path.path ~= "" then
        abs_path = root .. neotest.lib.files.sep .. path.path
      else
        abs_path = root
      end
      local path_elems = vim.split(abs_path, sep, { plain = true, trimempty = true })
      positions[#positions + 1] = {
        type = path.type,
        id = abs_path,
        path = abs_path,
        name = path_elems[#path_elems],
        range = nil,
      }
    end
    return positions
  end

  -- TODO: Clean this up
  local path_sep = neotest.lib.files.sep
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

  ---We use a custom string compare because it allows us to keep children under their directories
  ---For example with default string compare "x", "x/y", "x.z" would be sorted to "x", "x.z", "x/y" which then breaks
  ---paths_to_positions function because it assumes children are directly after their parents.
  ---@param x string
  ---@param y string
  local function path_compare(x, y)
    local target = string.byte("/")
    for i = 1, math.min(#x, #y) do
      local xe, ye = x:byte(i), y:byte(i)
      if xe ~= ye then
        if xe == target then
          return true
        elseif ye == target then
          return false
        end
        return xe < ye
      end
    end
    return #x < #y
  end

  for _, elem in pairs(paths) do
    table.insert(sorted_paths, elem)
  end
  table.sort(sorted_paths, function(a, b)
    return path_compare(a.path, b.path)
  end)
  return Tree.from_list(parse_tree(paths_to_positions(sorted_paths)), function(pos)
    return pos.id
  end)
end

--- Create a function that will take directory and attempt to match the provided
--- glob patterns against the contents of the directory.
---@param ... string Patterns to match e.g "*.py"
---@return fun(path: string): string | nil
function neotest.lib.files.match_root_pattern(...)
  local patterns = utils.tbl_flatten({ ... })
  return function(start_path)
    local start_parents = Path:new(start_path):parents()
    local home = os.getenv("HOME")
    local potential_roots = neotest.lib.files.is_dir(start_path)
        and vim.list_extend({ start_path }, start_parents)
      or start_parents
    local valid_roots = {}
    for index, value in ipairs(potential_roots) do
      if value == home then
        break
      end
      valid_roots[index] = value
    end
    for _, path in ipairs(valid_roots) do
      for _, pattern in ipairs(patterns) do
        for _, p in ipairs(nio.fn.glob(Path:new(path, pattern).filename, true, true)) do
          if neotest.lib.files.exists(p) then
            return path
          end
        end
      end
    end
  end
end

return neotest.lib.files
