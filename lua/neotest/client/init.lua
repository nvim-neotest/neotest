local async = require("neotest.async")
local config = require("neotest.config")
local logger = require("neotest.logging")
local lib = require("neotest.lib")

---@class neotest.InternalClient
---@field private _started boolean
---@field private _state neotest.ClientState
---@field private _events neotest.EventProcessor
---@field private _files_read table<string, boolean>
---@field private _adapters table<string, neotest.Adapter>
---@field private _adapter_group neotest.AdapterGroup
---@field private _runner neotest.TestRunner
local NeotestClient = {}

function NeotestClient:new(adapters)
  local events = require("neotest.client.events").processor()
  local state = require("neotest.client.state")(events)
  local processes = require("neotest.client.strategies")()
  local runner = require("neotest.client.runner")(processes)

  local neotest = {
    _started = false,
    _adapters = {},
    _events = events,
    _adapter_group = adapters,
    _state = state,
    _files_read = {},
    listeners = events.listeners,
    _runner = runner,
  }
  self.__index = self
  setmetatable(neotest, self)
  return neotest
end

---Run the given tree
---@async
---@param tree neotest.Tree
---@param args table
---@field adapter string: Adapter ID
---@field strategy string: Strategy to run commands with
---@field extra_args? string[]
function NeotestClient:run_tree(tree, args)
  args = args or {}
  local pos_ids = {}
  for _, pos in tree:iter() do
    table.insert(pos_ids, pos.id)
  end

  local root = tree:data()
  local adapter_id, adapter = self:_get_adapter(root.id, args.adapter)
  if not adapter_id or not adapter then
    logger.error("Adapter not found for position", root.id)
    return
  end
  self._state:update_running(adapter_id, root.id, pos_ids)
  local success, all_results = pcall(
    self._runner.run_tree,
    self._runner,
    tree,
    args,
    adapter,
    function(results)
      self._state:update_results(adapter_id, results, true)
    end
  )
  if not success then
    lib.notify(("%s: %s"):format(adapter.name, all_results), "warn")
    all_results = {}
    for _, pos in tree:iter() do
      all_results[pos.id] = { status = "skipped" }
    end
  end

  self._state:update_results(adapter_id, all_results)
end

---@async
---@param position neotest.Tree
---@param args? table
---@field adapter string Adapter ID
function NeotestClient:stop(position, args)
  args = args or {}
  local adapter_id = args.adapter or self:_get_running_adapters(position:data().id)[1]
  if not adapter_id then
    lib.notify("No running process found", "warn")
    return
  end
  self._runner:stop(position, adapter_id)
end

---Attach to the given running position.
---@param position neotest.Tree
---@param args? table
---@field adapter string Adapter ID
---@async
function NeotestClient:attach(position, args)
  args = args or {}
  local adapter_id = args.adapter or self:_get_running_adapters(position:data().id)[1]
  if not adapter_id then
    lib.notify("No running process found", "warn")
    return
  end
  self._runner:attach(position, adapter_id)
end

---@async
---@param file_path string
---@param row integer Zero-indexed row
---@param args table
---@field adapter string Adapter ID
---@return neotest.Tree | nil, string | nil
function NeotestClient:get_nearest(file_path, row, args)
  local positions, adapter_id = self:get_position(file_path, args)
  if not positions then
    return
  end
  local nearest
  for _, pos in positions:iter_nodes() do
    local data = pos:data()
    if data.range and data.range[1] <= row then
      nearest = pos
    else
      return nearest, adapter_id
    end
  end
  return nearest, adapter_id
end

---Get all known active adapters
---@async
---@return string[]
function NeotestClient:get_adapters()
  self:ensure_started()
  local active_adapters = {}
  for _, adapter in ipairs(self._adapters) do
    local root = self._state:positions(adapter.name)
    if root and #root:children() > 0 then
      table.insert(active_adapters, adapter.name)
    end
  end
  return active_adapters
end

function NeotestClient:has_started()
  return self._started
end

---Ensure that the client has initialised adapters and begun parsing files
function NeotestClient:ensure_started()
  if not self._started then
    self:_start()
  end
end

---@async
---@param position_id string
---@param args table
---@field adapter string Adapter ID
---@return neotest.Tree | nil, integer | nil
function NeotestClient:get_position(position_id, args)
  self:ensure_started()
  args = args or {}
  if position_id and vim.endswith(position_id, lib.files.sep) then
    position_id = string.sub(position_id, 1, #position_id - #lib.files.sep)
  end
  local adapter_id = self:_get_adapter(position_id, args.adapter, args.refresh)
  local positions = self._state:positions(adapter_id, position_id)

  return positions, adapter_id
end

---@param adapter string Adapter ID
---@return table<string, neotest.Result>
function NeotestClient:get_results(adapter)
  return self._state:results(adapter)
end

---@param position_id string
---@param args table
---@field adapter string Adapter ID
---@return boolean
function NeotestClient:is_running(position_id, args)
  args = args or {}
  if args.adapter then
    return self._state:running(args.adapter)[position_id] or false
  end
  return #self:_get_running_adapters(position_id) > 0
end

---@private
---@param position_id string
---@return string[]
function NeotestClient:_get_running_adapters(position_id)
  local running_adapters = {}
  for _, adapter_id in ipairs(self:get_adapters()) do
    if self._state:running(adapter_id)[position_id] then
      table.insert(running_adapters, adapter_id)
    end
  end
  return running_adapters
end

---@param file_path string
---@return string, neotest.Adapter
function NeotestClient:get_adapter(file_path)
  self:ensure_started()
  return self:_get_adapter(file_path, nil, false)
end

---@private
---@async
---@param path string
function NeotestClient:_update_positions(path, args)
  self:ensure_started()
  args = args or {}
  local adapter_id, adapter = self:_get_adapter(path, args.adapter, args.refresh)
  if not adapter then
    return
  end
  local success, positions = pcall(function()
    if lib.files.is_dir(path) then
      -- If existing tree then we have to find the point to merge the trees and update that path rather than trying to
      -- merge an orphan. This happens when a whole new directory is found (e.g. renamed an existing one).
      local existing_root = self:get_position(nil, { adapter = adapter_id })
      while
        existing_root
        and vim.startswith(path, existing_root:data().path)
        and not self:get_position(path, { adapter = adapter_id })
      do
        path = lib.files.parent(path)
        if not vim.startswith(path, existing_root:data().path) then
          return
        end
      end
      local files = lib.func_util.filter_list(adapter.is_test_file, lib.files.find({ path }))
      return lib.files.parse_dir_from_files(path, files)
    else
      return adapter.discover_positions(path)
    end
  end)
  if not success or not positions then
    logger.error("Couldn't find positions in path", path, positions)
    return
  end
  self._state:update_positions(adapter_id, positions)
  if positions:data().type == "dir" then
    local tree = self._state:positions(adapter_id, path)
    local parse_funcs = {}
    for _, node in tree:iter_nodes() do
      local pos = node:data()
      if pos.type == "file" and #node:children() == 0 then
        table.insert(parse_funcs, function()
          self:_update_positions(pos.id, args)
        end)
      end
    end
    -- This is extremely IO heavy so running together has large benefit thanks to using luv for IO.
    -- More than twice as fast compared to running in sequence for cpython repo. (~18000 tests)
    if #parse_funcs > 0 then
      async.util.join(parse_funcs)
    end
  end
end

---@private
---@async
---@return string | nil, neotest.Adapter | nil
function NeotestClient:_get_adapter(position_id, adapter_id, refresh)
  if not position_id and not adapter_id then
    return self._adapters[1].name
  end
  if adapter_id then
    for _, adapter in ipairs(self._adapters) do
      if adapter_id == adapter.name then
        return adapter_id, adapter
      end
    end
  end
  if not lib.files.is_dir(position_id) then
    for _, adapter in ipairs(self._adapters) do
      if
        self._state:positions(adapter.name, position_id)
        or (not lib.files.is_dir(position_id) and adapter.is_test_file(position_id))
      then
        return adapter.name, adapter
      end
    end
  else
    for _, adapter in ipairs(self._adapters) do
      local root = self._state:positions(adapter.name)
      if root and vim.startswith(position_id, root:data().path) then
        return adapter.name, adapter
      end
    end
  end

  if not lib.files.exists(position_id) or refresh == false then
    return
  end

  local new_adapter = self._adapter_group:get_file_adapter(position_id)
  if not new_adapter then
    return
  end

  table.insert(self._adapters, new_adapter)
  return new_adapter.name, new_adapter
end

---@private
---@async
function NeotestClient:_set_focused_file(path)
  local adapter_id = self:get_adapter(path)
  if not adapter_id then
    return
  end
  self._state:update_focused_file(adapter_id, path)
end

---@private
---@async
function NeotestClient:_start()
  if self._started then
    return
  end
  logger.info("Initialising client")
  local start = async.fn.localtime()
  self._started = true
  local augroup = async.api.nvim_create_augroup("NeotestClient", { clear = true })
  local function autocmd(event, callback)
    async.api.nvim_create_autocmd(event, {
      callback = callback,
      group = augroup,
    })
  end

  autocmd({ "BufAdd", "BufWritePost" }, function()
    local file_path = vim.fn.expand("<afile>:p")
    async.run(function()
      local adapter_id = self:_get_adapter(file_path, nil, true)
      if not adapter_id then
        return
      end
      if not self:get_position(file_path, { adapter = adapter_id }) then
        if config.discovery.enabled then
          self:_update_positions(lib.files.parent(file_path), { adapter = adapter_id })
        end
      end
      self:_update_positions(file_path, { adapter = adapter_id })
    end)
  end)

  autocmd("DirChanged", function()
    local dir = vim.fn.getcwd()
    async.run(function()
      self:_update_adapters(dir)
    end)
  end)

  autocmd({ "BufAdd", "BufDelete" }, function()
    local updated_dir = vim.fn.expand("<afile>:p:h")
    if config.discovery.enabled then
      async.run(function()
        self:_update_positions(updated_dir)
      end)
    end
  end)

  autocmd("BufEnter", function()
    local path = vim.fn.expand("<afile>:p")
    async.run(function()
      self:_set_focused_file(path)
    end)
  end)

  autocmd({ "CursorHold", "BufEnter" }, function()
    local path, line = vim.fn.expand("<afile>:p"), vim.fn.line(".")
    async.run(function()
      local pos, pos_adapter_id = self:get_nearest(path, line - 1)
      if not pos then
        return
      end
      self._state:update_focused_position(pos_adapter_id, pos:data().id)
    end)
  end)

  self:_update_adapters(async.fn.getcwd())

  if not config.discovery.enabled then
    self:_update_open_buf_poisitions()
  end
  local end_time = async.fn.localtime()
  logger.info("Initialisation finished in", end_time - start, "seconds")
  self:_set_focused_file(async.fn.expand("%:p"))
end

function NeotestClient:_update_open_buf_poisitions()
  for _, bufnr in ipairs(async.api.nvim_list_bufs()) do
    local file_path = async.api.nvim_buf_get_name(bufnr)
    self:_update_positions(file_path)
  end
end

---@private
---@async
function NeotestClient:_update_adapters(path)
  local adapters_with_root = lib.files.is_dir(path)
      and self._adapter_group:adapters_with_root_dir(path)
    or {}
  local adapters_with_bufs = self._adapter_group:adapters_matching_open_bufs()
  local found = {}
  for _, adapter in pairs(self._adapters) do
    found[adapter.name] = true
  end
  for _, entry in ipairs(adapters_with_root) do
    local adapter = entry.adapter
    local root = entry.root
    if not found[adapter.name] then
      table.insert(self._adapters, adapter)
      found[adapter.name] = true
    end
    if config.discovery.enabled then
      self:_update_positions(root, { adapter = adapter.name })
    end
  end
  local root = lib.files.is_dir(path) and path or async.fn.getcwd()
  for _, adapter in ipairs(adapters_with_bufs) do
    if not found[adapter.name] then
      table.insert(self._adapters, adapter)
      found[adapter.name] = true
    end
    if config.discovery.enabled then
      self:_update_positions(root, { adapter = adapter.name })
    end
  end
end

---@return neotest.InternalClient
return function(adapter_group)
  return NeotestClient:new(adapter_group)
end
