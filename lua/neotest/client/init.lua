local async = require("plenary.async")
local config = require("neotest.config")
local logger = require("neotest.logging")
local lib = require("neotest.lib")

---@class NeotestClient
---@field private _started boolean
---@field private _state NeotestState
---@field private _events NeotestEventProcessor
---@field private _processes NeotestProcessTracker
---@field listeners NeotestEventListeners
---@field _adapters table
local NeotestClient = {}

function NeotestClient:new(adapters, events, state, processes)
  events = events or require("neotest.client.events").processor()
  state = state or require("neotest.client.state")(events)
  processes = processes or require("neotest.client.strategies")()

  local neotest = {
    _started = false,
    _adapters = adapters,
    _events = events,
    _state = state,
    _processes = processes,
    listeners = events.listeners,
  }
  self.__index = self
  setmetatable(neotest, self)
  neotest:_add_listeners()
  return neotest
end

---@async
---@param tree? Tree
---@param args table
function NeotestClient:run_tree(tree, args)
  local pos_ids = {}
  for _, pos in tree:iter() do
    table.insert(pos_ids, pos.id)
  end

  self._state:update_running(tree:data().id, pos_ids)
  local results = self:_run_tree(tree, args)
  if tree:data().type ~= "test" then
    self:_collect_results(tree, results)
  end
  self._state:update_results(results)
end

---@param position Tree
function NeotestClient:stop(position)
  local running_process_root = self:is_running(position:data().id)
  if not running_process_root then
    lib.notify("No running process found", "warn")
    return
  end
  self._processes:stop(running_process_root)
end

function NeotestClient:_collect_results(tree, results)
  local root = tree:data()
  local running = {}
  for _, node in tree:iter_nodes() do
    local pos = node:data()
    if (pos.type == "test" or (pos.type == "file" and root.id ~= pos.id)) and results[pos.id] then
      for parent in node:iter_parents() do
        local parent_pos = parent:data()
        if parent_pos.id == root.id then
          break
        end
        local parent_result = results[parent_pos.id]
        local pos_result = results[pos.id]
        if not parent_result then
          parent_result = { id = parent_pos.id, status = "passed", output = pos_result.output }
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
  for _, node in tree:iter_nodes() do
    local pos = node:data()
    if pos.type == "test" or pos.type == "namespace" then
      if self:is_running(root.id) then
        table.insert(running, pos.id)
      end
      if not results[pos.id] and results[root.id] then
        local root_result = results[root.id]
        results[pos.id] = { id = pos.id, status = root_result.status, output = root_result.output }
      end
    end
  end
  self._state:update_running(root.id, running)
end

---@return table<string, NeotestResult>
function NeotestClient:_run_tree(tree, args)
  args = args or {}
  args.strategy = args.strategy or "integrated"
  local adapter = self:_get_adapter()
  local position = tree:data()

  async.util.scheduler()
  local spec = adapter.build_spec(vim.tbl_extend("force", args, {
    position = position,
  }))

  local results = {}
  if not spec then
    if position.type == "dir" then
      logger.warn("Adapter doesn't support running directories, attempting files")
      for _, node in tree:iter_nodes() do
        if node:data().type == "file" then
          results = vim.tbl_extend("error", self:_run_tree(node, args), results)
        end
      end
    elseif position.type == "file" then
      logger.warn("Adapter doesn't support running files")
      for _, node in tree:iter_nodes() do
        if node:data().type == "test" then
          results = vim.tbl_extend("error", self:_run_tree(node, args), results)
        end
      end
    end
  else
    spec.strategy = vim.tbl_extend(
      "force",
      spec.strategy or {},
      config.strategies[args.strategy] or {}
    )
    local process_result = self._processes:run(position.id, spec, args)
    results = adapter.results(spec, process_result)
    if vim.tbl_isempty(results) then
      logger.warn("Results returned were empty, setting all positions to failed")
      for _, pos in tree:iter() do
        results[pos.id] = {
          status = "failed",
          errors = {},
          output = process_result.output,
        }
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

---@async
---@param position Tree
function NeotestClient:attach(position)
  local node = position
  while node do
    local pos = node:data()
    if self._processes:attach(pos.id) then
      logger.debug("Attached to process for position", pos.name)
      return
    end
    node = node:parent()
  end
end

---@async
---@param file_path string
---@param row integer Zero-indexed row
---@return Tree
function NeotestClient:get_nearest(file_path, row)
  local positions = self:get_position(file_path)
  if not positions then
    return
  end
  local nearest
  for _, pos in positions:iter_nodes() do
    if pos:data().range[1] <= row then
      nearest = pos
    else
      return nearest
    end
  end
  return nearest
end

---@async
---@param position_id string
---@return Tree | nil
function NeotestClient:get_position(position_id, refresh)
  if not self._started then
    self:start()
  end
  if not position_id then
    return self._state:positions()
  end
  if position_id and vim.endswith(position_id, lib.files.sep) then
    position_id = string.sub(position_id, 1, #position_id - #lib.files.sep)
  end
  local positions = self._state:positions(position_id)
  if positions or refresh == false then
    return positions
  end
  if lib.files.exists(position_id) then
    self:update_positions(position_id)
    return self._state:positions(position_id)
  end
end

---@return table<string, NeotestResult>
function NeotestClient:get_results()
  return self._state:results()
end

function NeotestClient:is_running(position_id)
  return self._state:running()[position_id] or false
end

function NeotestClient:is_test_file(file_path)
  if self._state:positions(file_path) then
    return true
  end
  local adapter = self:_get_adapter(file_path)
  if not adapter then
    return false
  end
  if adapter.is_test_file(file_path) then
    return true
  end
end

---@async
---@param file_path string
function NeotestClient:update_positions(file_path)
  local adapter = self:_get_adapter()
  if not adapter then
    return
  end
  if not self._started then
    self:start()
  end
  local success, positions = pcall(adapter.discover_positions, file_path)
  if not success then
    logger.info("Couldn't find positions in file", file_path, positions)
    return
  end
  self._state:update_positions(positions)
end

function NeotestClient:start()
  self._started = true
  self:_get_adapter(nil, true)
  self:update_positions(async.fn.getcwd())
  vim.cmd([[
      augroup Neotest 
        au!
        autocmd BufAdd,BufWritePost * lua require("neotest")._update_positions(vim.fn.expand("<afile>:p"))
        autocmd DirChanged * lua require("neotest")._update_files(vim.fn.getcwd())
        autocmd BufDelete * lua require("neotest")._update_files(vim.fn.expand("<afile>:h"))
      augroup END
    ]])
end
---@param file_path? string
---@return NeotestAdapter
function NeotestClient:_get_adapter(file_path, from_dir)
  return self._adapters.get_adapter({ file_path = file_path, from_dir = from_dir })
end

function NeotestClient:_add_listeners()
  self._events.listeners.discover_positions["neotest-client-update-buffers"] = function(tree)
    if tree:data().type == "dir" then
      local adapter = self:_get_adapter()
      for _, pos in tree:iter() do
        if pos.type == "file" then
          local file_path = pos.path

          local bufnr = async.api.nvim_eval("bufnr('" .. file_path .. "')")
          -- If it's not listed, it could have been opened in background by
          -- another plugin
          local is_open = bufnr ~= -1 and async.api.nvim_buf_get_option(bufnr, "buflisted")
          if is_open and #self._state:positions(file_path):children() == 0 then
            local positions = adapter.discover_positions(file_path)
            self._state:update_positions(positions)
          end
        end
      end
    end
  end

  self._events.listeners.discover_positions["neotest-client-update-results"] = function(tree)
    if tree:data().type == "file" then
      local new_results = {}
      local results = self:get_results()
      for _, pos in tree:iter() do
        new_results[pos.id] = results[pos.id]
      end
      self:_collect_results(tree, new_results)
      self._state:update_results(new_results)
    end
  end
end

---@param events? NeotestEventProcessor
---@param state? NeotestState
---@param processes? NeotestProcessTracker
---@return NeotestClient
return function(events, state, processes)
  return NeotestClient:new(events, state, processes)
end
