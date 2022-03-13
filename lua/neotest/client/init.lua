local async = require("neotest.async")
local config = require("neotest.config")
local logger = require("neotest.logging")
local lib = require("neotest.lib")

---@class neotest.Client
---@field private _started boolean
---@field private _state NeotestState
---@field private _events NeotestEventProcessor
---@field private _processes NeotestProcessTracker
---@field private _files_read table<string, boolean>
---@field private _adapters table<integer, neotest.Adapter>
---@field private _adapter_group neotest.AdapterGroup
---@field listeners NeotestEventListeners
local NeotestClient = {}

function NeotestClient:new(adapters, events, state, processes)
  adapters = adapters or require("neotest.adapters")
  events = events or require("neotest.client.events").processor()
  state = state or require("neotest.client.state")(events)
  processes = processes or require("neotest.client.strategies")()

  local neotest = {
    _started = false,
    _adapters = {},
    _events = events,
    _adapter_group = adapters,
    _state = state,
    _processes = processes,
    _files_read = {},
    listeners = events.listeners,
  }
  self.__index = self
  setmetatable(neotest, self)
  return neotest
end

---Run the given tree
---@async
---@param tree? neotest.Tree
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

  local pos = tree:data()
  local adapter_id, adapter = self:_get_adapter(pos.id, args.adapter)
  if not adapter_id then
    logger.error("Adapter not found for position", pos.id)
    return
  end
  self._state:update_running(adapter_id, pos.id, pos_ids)
  local results = self:_run_tree(tree, args, adapter)
  if pos.type ~= "test" then
    self:_collect_results(adapter_id, tree, results)
  end
  if pos.type == "test" or pos.type == "namespace" then
    results[pos.path] = nil
  end
  self._state:update_results(adapter_id, results)
end

---@async
---@param position neotest.Tree
---@param args table
---@field adapter string Adapter ID
function NeotestClient:stop(position, args)
  args = args or {}
  local running_process_root = self:_get_process_key(position, args)
  if not running_process_root then
    lib.notify("No running process found", "warn")
    return
  end
  self._processes:stop(running_process_root)
end

---@param position neotest.Tree
---@return string | nil
function NeotestClient:_get_process_key(position, args)
  local get_adapter = function(pos_id)
    if args.adapter then
      return args.adapter
    end
    local running_adapters = self:_get_running_adapters(pos_id)
    return running_adapters[1]
  end

  local get_proc_key = function(pos_id)
    local adapter = get_adapter(pos_id)
    return adapter and self:_create_process_key(adapter, pos_id)
  end

  local is_running = function(pos_id)
    local proc_key = get_proc_key(pos_id)
    return proc_key and self._processes:exists(proc_key)
  end

  local running_process_root

  if not is_running(position:data().id) then
    for parent in position:iter_parents() do
      if is_running(parent:data().id) then
        running_process_root = parent:data().id
        break
      end
    end
  else
    running_process_root = position:data().id
  end
  if running_process_root then
    return get_proc_key(running_process_root)
  end
end

function NeotestClient:_create_process_key(adapter_id, pos_id)
  return adapter_id .. "-" .. pos_id
end

---@private
---@async
function NeotestClient:_collect_results(adapter_id, tree, results)
  local root = tree:data()
  local running = {}
  for _, node in tree:iter_nodes() do
    local pos = node:data()

    if pos.type == "test" and results[pos.id] then
      for parent in node:iter_parents() do
        local parent_pos = parent:data()
        if not lib.positions.contains(root, parent_pos) then
          break
        end

        local parent_result = results[parent_pos.id]
        local pos_result = results[pos.id]
        if not parent_result then
          parent_result = { status = "passed", output = pos_result.output }
        end

        if pos_result.status ~= "skipped" then
          if parent_result.status == "passed" then
            parent_result.status = pos_result.status
          end
        end

        if pos_result.errors then
          parent_result.errors = vim.list_extend(parent_result.errors or {}, pos_result.errors)
        end

        results[parent_pos.id] = parent_result
      end
    end
  end

  local root_result = results[root.id]
  for _, node in tree:iter_nodes() do
    local pos = node:data()
    if pos.type ~= "dir" then
      if pos.type == "file" then
        -- Files not being present means that they were skipped (probably)
        if not results[pos.id] and root_result then
          results[pos.id] = { status = "skipped", output = root.output }
        end
      else
        if self:is_running(root.id) then
          table.insert(running, pos.id)
        end
        -- Tests and namespaces not being present means that they failed to even start, count as root result
        if not results[pos.id] and root_result then
          results[pos.id] = { status = root_result.status, output = root_result.output }
        end
      end
    end
  end
  if not vim.tbl_isempty(running) then
    self._state:update_running(adapter_id, root.id, running)
  end
end

---@private
---@async
---@param tree neotest.Tree
---@param args table
---@param adapter neotest.Adapter
---@return table<string, neotest.Result>
function NeotestClient:_run_tree(tree, args, adapter)
  args = args or {}
  args.strategy = args.strategy or "integrated"
  local position = tree:data()

  local spec = adapter.build_spec(vim.tbl_extend("force", args, {
    tree = tree,
  }))

  local results = {}

  if not spec then
    local function run_pos_types(pos_type)
      local async_runners = {}
      for _, node in tree:iter_nodes() do
        if node:data().type == pos_type then
          table.insert(async_runners, function()
            return self:_run_tree(node, args, adapter)
          end)
        end
      end
      local all_results = {}
      for i, res in ipairs(async.util.join(async_runners)) do
        all_results[i] = res[1]
      end
      return vim.tbl_extend("error", {}, unpack(all_results))
    end
    if position.type == "dir" then
      logger.warn("Adapter doesn't support running directories, attempting files")
      results = run_pos_types("file")
    elseif position.type == "file" then
      logger.warn("Adapter doesn't support running files")
      results = run_pos_types("test")
    end
  else
    spec.strategy = vim.tbl_extend(
      "force",
      spec.strategy or {},
      config.strategies[args.strategy] or {}
    )
    local process_result = self._processes:run(
      self:_create_process_key(adapter.name, position.id),
      spec,
      args
    )
    results = adapter.results(spec, process_result, tree)
    if vim.tbl_isempty(results) then
      if #tree:children() ~= 0 then
        logger.warn("Results returned were empty, setting all positions to failed")
        for _, pos in tree:iter() do
          results[pos.id] = {
            status = "failed",
            errors = {},
            output = process_result.output,
          }
        end
      else
        results[tree:data().id] = { status = "skipped", output = process_result.output }
      end
    else
      for _, result in pairs(results) do
        if not result.output then
          result.output = process_result.output
        end
      end
    end
  end
  return results
end

---Attach to the given running position.
---@param position neotest.Tree
---@param args table
---@field adapter string Adapter ID
---@async
function NeotestClient:attach(position, args)
  args = args or {}
  local running_process_root = self:_get_process_key(position, args)
  if not running_process_root then
    lib.notify("No running process found", "warn")
    return
  end
  if self._processes:attach(running_process_root) then
    logger.debug("Attached to process", running_process_root, "for position", position:data().id)
    return
  end
end

---@async
---@param file_path string
---@param row integer Zero-indexed row
---@param args table
---@field adapter string Adapter ID
---@return neotest.Tree | nil, integer | nil
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
  local adapter_id = self:_get_adapter(position_id, args.adapter)
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
  return self:_get_adapter(file_path)
end

---@private
---@async
---@param path string
function NeotestClient:_update_positions(path, args)
  self:ensure_started()
  args = args or {}
  local adapter_id, adapter = self:_get_adapter(path, args.adapter)
  if not adapter then
    return
  end
  local success, positions = pcall(function()
    if lib.files.is_dir(path) then
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
  local existing = self:get_position(path, { refresh = false, adapter = adapter_id })
  if positions:data().type == "file" and existing and #existing:children() == 0 then
    self:_propagate_results_to_new_positions(adapter_id, positions)
  end
  self._state:update_positions(adapter_id, positions)
  if positions:data().type == "dir" then
    local tree = self._state:positions(adapter_id, path)
    local parse_funcs = {}
    for _, node in tree:iter_nodes() do
      local pos = node:data()
      if pos.type == "file" and #node:children() == 0 then
        table.insert(parse_funcs, function()
          self:_update_positions(pos.id, { adapter = adapter_id })
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
function NeotestClient:_get_adapter(position_id, adapter_id)
  if not position_id and not adapter_id then
    adapter_id = self._adapters[1].name
  end
  if adapter_id then
    for _, adapter in ipairs(self._adapters) do
      if adapter_id == adapter.name then
        return adapter_id, adapter
      end
    end
  end
  for _, adapter in ipairs(self._adapters) do
    if self._state:positions(adapter.name, position_id) or adapter.is_test_file(position_id) then
      return adapter.name, adapter
    end
  end

  if not lib.files.exists(position_id) then
    return
  end

  local new_adapter = self._adapter_group.get_file_adapter(position_id)
  if not new_adapter then
    return
  end

  table.insert(self._adapters, new_adapter)
  return new_adapter.name, new_adapter
end

---@private
---@async
function NeotestClient:_propagate_results_to_new_positions(adapter_id, tree)
  local new_results = {}
  local results = self:get_results()
  for _, pos in tree:iter() do
    new_results[pos.id] = results[pos.id]
  end
  self:_collect_results(adapter_id, tree, new_results)
  if not vim.tbl_isempty(new_results) then
    self._state:update_results(adapter_id, new_results)
  end
end

---@private
---@async
function NeotestClient:_set_focused(path)
  local adapter_id = self:get_adapter(path)
  if not adapter_id then
    return
  end
  self._state:update_focused(adapter_id, path)
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
  vim.schedule(function()
    vim.cmd([[
      augroup NeotestClient
        au!
        autocmd BufAdd,BufWritePost * lua require("neotest")._update_positions(vim.fn.expand("<afile>:p"))
        autocmd DirChanged * lua require("neotest")._dir_changed()
        autocmd BufAdd,BufDelete * lua require("neotest")._update_files(vim.fn.expand("<afile>:p:h"))
        autocmd BufEnter * lua require("neotest")._focus_file(vim.fn.expand("<afile>:p"))
      augroup END
    ]])
  end)
  self:_update_adapters(async.fn.getcwd())
  local end_time = async.fn.localtime()
  logger.info("Initialisation finished in", end_time - start, "seconds")
  self:_set_focused(async.fn.expand("%:p"))
end

---@private
---@async
function NeotestClient:_update_adapters(path)
  local adapters_with_root = lib.files.is_dir(path)
      and self._adapter_group.adapters_with_root_dir(path)
    or {}
  local adapters_with_bufs = self._adapter_group.adapters_matching_open_bufs()
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
    self:_update_positions(root, { adapter = adapter.name })
  end
  local root = lib.files.is_dir(path) and path or async.fn.getcwd()
  for _, adapter in ipairs(adapters_with_bufs) do
    if not found[adapter.name] then
      table.insert(self._adapters, adapter)
      found[adapter.name] = true
    end
    self:_update_positions(root, { adapter = adapter.name })
  end
end
---@param events? NeotestEventProcessor
---@param state? NeotestState
---@param processes? NeotestProcessTracker
---@return neotest.Client
return function(adapter_group, events, state, processes)
  return NeotestClient:new(adapter_group, events, state, processes)
end
