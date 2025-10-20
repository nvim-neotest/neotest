local nio = require("nio")
local config = require("neotest.config")
local logger = require("neotest.logging")
local lib = require("neotest.lib")
local NeotestState = require("neotest.client.state")
local NeotestRunner = require("neotest.client.runner")
local NeotestEventProcessor = require("neotest.client.events").processor
local NeotestProcessTracker = require("neotest.client.strategies")

local neotest = {}

---@toc_entry Neotest Client
---@text
--- The neotest client is the core of neotest, it communicates with adapters,
--- running tests and collecting results.
--- Most of the client methods are async and so need to be run in an async
--- context (i.e. `require("nio").run(function() ... end))
--- The client starts lazily, meaning that no parsing of tests will be performed
--- until it is required. Care should be taken to not use the client methods on
--- start because it can slow down startup.
---@class neotest.Client
---@field private _started boolean
---@field private _state neotest.ClientState
---@field private _events neotest.EventProcessor
---@field private _adapters table<string, neotest.Adapter>
---@field private _adapter_group neotest.AdapterGroup
---@field private _runner neotest.TestRunner
---@field listeners neotest.ConsumerListeners
neotest.Client = {}

---@class neotest.ConsumerListeners
---@field discover_positions fun(adapter_id: string, tree: neotest.Tree)
---@field run fun(adapter_id: string, root_id: string, position_ids: string[])
---@field results fun(adapter_id: string, results: table<string, neotest.Result>, partial: boolean)
---@field test_file_focused fun(adapter_id: string, file_path: string)>
---@field test_focused fun(adapter_id: string, position_id: string)>
---@field starting fun()
---@field started fun()
---@type neotest.Client

function neotest.Client:new(adapters)
  local events = NeotestEventProcessor()

  local client = {
    _started = false,
    _adapters = {},
    _adapter_group = adapters,
    _events = events,
    listeners = events.listeners,
  }
  ---@private
  self.__index = self
  setmetatable(client, self)
  return client
end

---@class neotest.client.RunTreeArgs
---@field adapter? string Adapter ID, if not given the first adapter found with chosen position is used.
---@field strategy? "integrated"|"dap"|string|neotest.Strategy Strategy to run commands with
---@field extra_args? string[] Arguments supplied to the test adapter to add to the test process arguments
---@field env? table<string, string> Environment variables for the test process
---@field cwd? string Working directory for the test process
---@field concurrent? false|number Override concurrency settings for running tests

--- Run the given tree
---@async
---@param tree neotest.Tree
---@param args neotest.client.RunTreeArgs
function neotest.Client:run_tree(tree, args)
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
  local errmsg = ""
  local success, all_results = xpcall(function()
    return self._runner.run_tree(self._runner, tree, args, adapter_id, adapter, function(results)
      self._state:update_results(adapter_id, results, true)
    end)
  end, function(err)
    errmsg = debug.traceback(err, 1)
  end)

  if not success then
    lib.notify(("%s: %s"):format(adapter.name, errmsg), "warn")
    all_results = {}
    for _, pos in tree:iter() do
      all_results[pos.id] = { status = "skipped" }
    end
  end

  self._state:update_results(adapter_id, all_results)
end

---@return table[]
function neotest.Client:running_positions()
  return self._runner:running()
end

---@class neotest.client.StopArgs
---@field adapter string Adapter ID

---@async
---@param position neotest.Tree
---@param args? neotest.client.StopArgs
function neotest.Client:stop(position, args)
  args = args or {}
  local adapter_id = args.adapter or self:_get_running_adapters(position:data().id)[1]
  if not adapter_id then
    lib.notify("No running process found", "warn")
    return
  end
  self._runner:stop(position, adapter_id)
end

---@class neotest.client.AttachArgs
---@field adapter string Adapter ID

--- Attach to the given running position.
---@async
---@param position neotest.Tree
---@param args? neotest.client.AttachArgs
function neotest.Client:attach(position, args)
  args = args or {}
  local adapter_id = args.adapter or self:_get_running_adapters(position:data().id)[1]
  if not adapter_id then
    lib.notify("No running process found", "warn")
    return
  end
  self._runner:attach(position, adapter_id)
end

---@class neotest.client.GetNearestArgs
---@field adapter string Adapter ID

---@async
---@param file_path string
---@param row integer Zero-indexed row
---@param args neotest.client.GetNearestArgs
---@return neotest.Tree|nil,string|nil
function neotest.Client:get_nearest(file_path, row, args)
  local positions, adapter_id = self:get_position(file_path, args)
  if not positions then
    return
  end
  local nearest
  for _, node in positions:iter_nodes() do
    node = node:closest_node_with("range") or node
    local range = node:data().range
    if range and range[1] <= row then
      nearest = node
    else
      return nearest, adapter_id
    end
  end
  return nearest, adapter_id
end

---Get all known active adapters
---@async
---@return string[]
function neotest.Client:get_adapters()
  self:_ensure_started()
  local active_adapters = {}
  for adapter_id, _ in pairs(self._adapters) do
    local root = self._state:positions(adapter_id)
    if root and #root:children() > 0 then
      table.insert(active_adapters, adapter_id)
    end
  end
  return active_adapters
end

---Ensure that the client has initialised adapters and begun parsing files
---@private
function neotest.Client:_ensure_started()
  if not self._started then
    self:_start()
  end
end

---@class neotest.client.GetPositionArgs
---@field adapter? string Adapter ID

---@async
---@param position_id? string
---@param args neotest.client.GetPositionArgs
---@return neotest.Tree|nil,string|nil
function neotest.Client:get_position(position_id, args)
  self:_ensure_started()
  args = args or {}
  if position_id and vim.endswith(position_id, lib.files.sep) then
    position_id = string.sub(position_id, 1, #position_id - #lib.files.sep)
  end
  local adapter_id = self:_get_adapter(position_id, args.adapter)
  local positions = self._state:positions(adapter_id, position_id)

  return positions, adapter_id
end

---@param adapter string Adapter ID
---@return table<string, neotest.Result>
function neotest.Client:get_results(adapter)
  return self._state:results(adapter)
end

---@class neotest.client.IsRunningArgs
---@field adapter string Adapter ID

---@param position_id string
---@param args neotest.client.IsRunningArgs
---@return boolean
function neotest.Client:is_running(position_id, args)
  args = args or {}
  if args.adapter then
    return self._state:running(args.adapter)[position_id] or false
  end
  return #self:_get_running_adapters(position_id) > 0
end

---@param position_id string
---@return string[]
---@private
function neotest.Client:_get_running_adapters(position_id)
  local running_adapters = {}
  for _, adapter_id in ipairs(self:get_adapters()) do
    if self._state:running(adapter_id)[position_id] then
      table.insert(running_adapters, adapter_id)
    end
  end
  return running_adapters
end

---@async
---@param file_path string
---@return string?
---@return neotest.Adapter?
function neotest.Client:get_adapter(file_path)
  self:_ensure_started()
  return self:_get_adapter(file_path, nil)
end

---@async
---@param path string
---@private
function neotest.Client:_update_positions(path, args)
  if not lib.files.exists(path) then
    return
  end
  self:_ensure_started()
  args = args or {}
  local adapter_id, adapter = self:_get_adapter(path, args.adapter)
  if not adapter then
    return
  end
  xpcall(function()
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
      logger.info("Searching", path, "for test files")
      local root_path = existing_root and existing_root:data().path or path
      local files = lib.func_util.filter_list(
        adapter.is_test_file,

        lib.files.find(path, {
          filter_dir = function(...)
            return (not adapter.filter_dir or adapter.filter_dir(...))
              and (
                not config.projects[root_path].discovery.filter_dir
                or config.projects[root_path].discovery.filter_dir(...)
              )
          end,
        })
      )
      local positions = lib.files.parse_dir_from_files(path, files)
      logger.debug("Found", positions)
      self._state:update_positions(adapter_id, positions)
      self:_parse_files(adapter_id, path, files)
    else
      logger.info("Parsing", path)
      local positions = adapter.discover_positions(path)
      if not positions then
        logger.info("No positions found in", path)
        return
      end
      logger.debug("Found", positions)
      self._state:update_positions(adapter_id, positions)
    end
  end, function(msg)
    logger.error("Couldn't find positions in path", path, debug.traceback(msg, 2))
  end)
end

---@private
function neotest.Client:_parse_files(adapter_id, root, paths)
  local function worker()
    while #paths > 0 do
      self:_update_positions(table.remove(paths), { adapter = adapter_id })
    end
  end

  local workers = {}
  for _ = 1, config.projects[root].discovery.concurrent do
    table.insert(workers, worker)
  end
  logger.info("Discovering files with", #workers, "workers")
  nio.gather(workers)
end

---@async
---@return string | nil, neotest.Adapter | nil
---@private
function neotest.Client:_get_adapter(position_id, adapter_id)
  if adapter_id then
    return adapter_id, self._adapters[adapter_id]
  end

  assert(position_id)

  local function find_adapter()
    for a_id, adapter in pairs(self._adapters) do
      if self._state:positions(a_id, position_id) then
        return a_id, adapter
      end

      local root = self._state:positions(a_id)
      if
        (not root or vim.startswith(position_id, root:data().path))
        and (lib.files.is_dir(position_id) or adapter.is_test_file(position_id))
      then
        return a_id, adapter
      end
    end
  end

  -- First attempt to find adapter
  local found_id, found_adapter = find_adapter()
  if found_id then
    return found_id, found_adapter
  end

  -- If no adapter is found and client is started, update adapters for this path's directory and try again
  if self._started then
    local dir = lib.files.is_dir(position_id) and position_id or lib.files.parent(position_id)
    self:_update_adapters(dir)
    return find_adapter()
  end
end

---@async
---@private
function neotest.Client:_set_focused_file(path)
  local adapter_id = self:get_adapter(path)
  if not adapter_id then
    return
  end
  self._state:update_focused_file(adapter_id, path)
end

---@async
---@private
function neotest.Client:_start(args)
  args = args or {}
  if self._started and not args.force then
    return
  end
  self._adapters = {}
  if not lib.subprocess.enabled() then
    lib.subprocess.init()
  end
  local process_tracker = NeotestProcessTracker()
  self._runner = NeotestRunner(process_tracker)
  self._state = NeotestState(self._events)

  logger.info("Initialising client")
  local start = vim.loop.now()
  self._started = true
  self._events:emit("starting")
  local augroup = nio.api.nvim_create_augroup("neotest.Client", { clear = true })
  local function autocmd(event, callback)
    if args.autocmds == false then
      return
    end
    nio.api.nvim_create_autocmd(event, {
      callback = callback,
      group = augroup,
    })
  end

  autocmd({ "BufAdd", "BufWritePost" }, function(ev)
    if ev.file == "" then
      return
    end

    local file_path = vim.fn.fnamemodify(ev.file, ":p")

    if not lib.files.exists(file_path) then
      return
    end

    nio.run(function()
      local adapter_id = self:_get_adapter(file_path)
      if not adapter_id then
        for a_id, _ in pairs(self._adapters) do
          local root = self:get_position(nil, { adapter = a_id })
          if not root then
            return
          end
          if vim.startswith(file_path, root:data().path) then
            logger.info(
              "Not updating positions for",
              file_path,
              "as it's in a known directory and no adapter matched"
            )
            return
          end
        end
        local adapter = self._adapter_group:adapter_matching_path(file_path)
        if not adapter then
          return
        end
        --- Provide file paths parent because we could be outside of the root dir.
        local root = adapter.root(lib.files.parent(file_path)) or vim.loop.cwd()
        adapter_id = ("%s:%s"):format(adapter.name, root)
        self._adapters[adapter_id] = adapter

        if config.projects[root].discovery.enabled then
          self:_update_positions(root, { adapter = adapter_id })
        else
          self:_update_open_buf_positions(adapter_id)
        end
      end
      if not self:get_position(file_path, { adapter = adapter_id }) then
        local root = self._state:positions(adapter_id)
        if config.projects[root and root:data().path or vim.loop.cwd()].discovery.enabled then
          self:_update_positions(lib.files.parent(file_path), { adapter = adapter_id })
        end
      end
      self:_update_positions(file_path, { adapter = adapter_id })
    end)
  end)

  autocmd("DirChanged", function()
    local dir = vim.loop.cwd()
    nio.run(function()
      self:_update_adapters(dir)
    end)
  end)

  autocmd({ "BufAdd", "BufDelete" }, function(ev)
    if ev.file == "" then
      return
    end
    local updated_dir = vim.fn.fnamemodify(ev.file, ":p:h")
    nio.run(function()
      local adapter_id = self:_get_adapter(updated_dir, nil)
      if not adapter_id then
        return
      end
      local root = self._state:positions(adapter_id)
      if config.projects[root and root:data().path or vim.loop.cwd()].discovery.enabled then
        self:_update_positions(updated_dir)
      end
    end)
  end)

  autocmd("BufEnter", function(ev)
    if ev.file == "" then
      return
    end
    local path = vim.fn.fnamemodify(ev.file, ":p")

    if not lib.files.exists(path) then
      return
    end

    nio.run(function()
      self:_set_focused_file(path)
    end)
  end)

  autocmd({ "CursorHold", "BufEnter" }, function()
    if vim.fn.expand("%") == "" then
      return
    end
    local path, line = vim.fn.expand("%:p"), vim.fn.line(".")

    if not lib.files.exists(path) then
      return
    end

    nio.run(function()
      local pos, pos_adapter_id = self:get_nearest(path, line - 1)
      if not pos then
        return
      end
      self._state:update_focused_position(pos_adapter_id, pos:data().id)
    end)
  end)

  self:_update_adapters(vim.loop.cwd())

  local run_time = (vim.loop.now() - start) / 1000
  logger.info("Initialisation finished in", run_time, "seconds")
  self:_set_focused_file(nio.fn.expand("%:p"))
  self._events:emit("started")
  return run_time
end

---@async
---@private
function neotest.Client:_update_open_buf_positions(adapter_id)
  local adapter = self._adapters[adapter_id]
  for _, bufnr in ipairs(nio.api.nvim_list_bufs()) do
    local name = nio.api.nvim_buf_get_name(bufnr)
    local file_path = lib.files.path.real(name) or name
    if adapter.is_test_file(file_path) then
      self:_update_positions(file_path, { adapter = adapter_id })
    end
  end
end

---@async
---@private
function neotest.Client:_update_adapters(dir)
  local adapters_with_root = lib.files.is_dir(dir)
      and self._adapter_group:adapters_with_root_dir(dir)
    or {}

  local adapters_with_bufs =
    self._adapter_group:adapters_matching_open_bufs(lib.func_util.map(function(i, entry)
      return i, entry.root
    end, adapters_with_root))

  local root = lib.files.is_dir(dir) and dir or vim.loop.cwd()
  for _, adapter in ipairs(adapters_with_bufs) do
    adapters_with_root[#adapters_with_root + 1] = { adapter = adapter, root = root }
  end

  local found = {}
  for adapter_id, _ in pairs(self._adapters) do
    found[adapter_id] = true
  end

  ---@type table<string, {adapter: neotest.Adapter, root: string}>
  local new_adapters = {}

  for _, entry in ipairs(adapters_with_root) do
    local adapter = entry.adapter
    local adapter_id = ("%s:%s"):format(adapter.name, entry.root)
    if not found[adapter_id] then
      self._adapters[adapter_id] = adapter
      found[adapter_id] = true
      new_adapters[adapter_id] = entry
    end
  end

  local to_add = {}
  for _, entry in pairs(new_adapters) do
    to_add[#to_add + 1] = entry.adapter.is_test_file
  end
  if #to_add > 0 and lib.subprocess.enabled() then
    local suc, err = pcall(lib.subprocess.add_to_rtp, to_add)
    if not suc then
      logger.error("Failed to add adapter to rtp", err)
    end
  end

  for adapter_id, entry in pairs(new_adapters) do
    if config.projects[entry.root].discovery.enabled then
      self:_update_positions(entry.root, { adapter = adapter_id })
    else
      self:_update_open_buf_positions(adapter_id)
    end
  end
end

---@return neotest.Client
---@private
return function(adapter_group)
  return neotest.Client:new(adapter_group)
end
