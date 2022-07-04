local async = require("neotest.async")
local config = require("neotest.config")
local logger = require("neotest.logging")
local lib = require("neotest.lib")

---@class neotest.TestRunner
---@field _processes neotest.ProcessTracker
local TestRunner = {}

function TestRunner:new(processes)
  self.__index = self
  return setmetatable({
    _processes = processes,
  }, self)
end

---@private
---@async
---@param tree neotest.Tree
---@param args table
---@param adapter neotest.Adapter
---@return table<string, neotest.Result>
function TestRunner:_run_tree(tree, args, adapter)
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
      logger.warn(("%s doesn't support running directories, attempting files"):format(adapter.name))
      results = run_pos_types("file")
    elseif position.type ~= "test" then
      logger.warn(("%s doesn't support running %ss"):format(adapter.name, position.type))
      results = run_pos_types("test")
    else
      error(("%s returned no data to run tests"):format(adapter.name))
    end
  else
    spec.strategy = vim.tbl_extend(
      "force",
      spec.strategy or {},
      config.strategies[args.strategy] or {}
    )
    if vim.tbl_isempty(spec.env or {}) then
      spec.env = nil
    end
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

function TestRunner:_create_process_key(adapter_id, pos_id)
  return adapter_id .. "-" .. pos_id
end

---@param position neotest.Tree
---@return string | nil
function TestRunner:get_process_key(position, adapter_id)
  local is_running = function(pos_id)
    local proc_key = self:_create_process_key(adapter_id, pos_id)
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
    return self:_create_process_key(adapter_id, running_process_root)
  end
end

function TestRunner:stop(position, adapter_id)
  local running_process_root = self:get_process_key(position, adapter_id)
  if not running_process_root then
    return
  end
  if self._processes:stop(running_process_root) then
    logger.debug("Stopped process", running_process_root, "for position", position:data().id)
  end
end

function TestRunner:attach(position, adapter_id)
  local running_process_root = self:get_process_key(position, adapter_id)
  if not running_process_root then
    return
  end
  if self._processes:attach(running_process_root) then
    logger.debug("Attached to process", running_process_root, "for position", position:data().id)
  end
end

---@async
function TestRunner:collect_results(tree, results)
  local root = tree:data()
  for _, node in tree:iter_nodes() do
    local pos = node:data()

    if results[pos.id] then
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
        -- Tests and namespaces not being present means that they failed to even start, count as root result
        if not results[pos.id] and root_result then
          results[pos.id] = { status = root_result.status, output = root_result.output }
        end
      end
    end
  end
end

return function(processes)
  return TestRunner:new(processes)
end
