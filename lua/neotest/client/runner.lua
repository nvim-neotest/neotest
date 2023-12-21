local nio = require("nio")
local config = require("neotest.config")
local logger = require("neotest.logging")

---@class neotest.TestRunner
---@field _processes neotest.ProcessTracker
---@field _running table<string, table>
local TestRunner = {}

function TestRunner:new(processes)
  self.__index = self
  return setmetatable({
    _processes = processes,
    _running = {},
  }, self)
end

---@async
---@param tree neotest.Tree
---@param args table
---@param adapter neotest.Adapter
function TestRunner:run_tree(tree, args, adapter_id, adapter, on_results)
  if self._running[tree:data().id] then
    logger.warn("Position already running:", tree:data().id)
  end
  self._running[tree:data().id] = { position = tree, adapter = adapter_id }
  local all_results = {}
  local results_callback = function(root, results, output_path)
    local function fill_results(missing_results)
      for pos_id, result in pairs(missing_results) do
        results[pos_id] = result
      end
    end

    fill_results(self:_missing_results(root, results, not output_path))

    if output_path then
      for _, pos in root:iter() do
        if not results[pos.id] and not all_results[pos.id] then
          results[pos.id] = {
            status = "failed",
            errors = {},
            output = output_path,
          }
        end
      end

      for _, result in pairs(results) do
        if not result.output then
          result.output = output_path
        end
      end
    end

    for pos_id, result in pairs(results) do
      all_results[pos_id] = result
    end
    fill_results(self:_missing_results(tree, all_results, true))
    on_results(results)
  end

  local root = tree:root():data().path
  args = vim.tbl_extend("keep", args or {}, { strategy = config.projects[root].default_strategy })

  self:_run_tree(tree, args, adapter_id, adapter, results_callback)

  self._running[tree:data().id] = nil
  return all_results
end

function TestRunner:running()
  return vim.tbl_values(self._running)
end

function TestRunner:_run_tree(tree, args, adapter_id, adapter, results_callback)
  local specs = adapter.build_spec(vim.tbl_extend("force", args, { tree = tree }))

  if not specs then
    self:_run_broken_down_tree(tree, args, adapter_id, adapter, results_callback)
    return
  end

  if not specs[1] then
    specs = { specs }
  end
  local async_runners = {}
  for _, spec in ipairs(specs) do
    table.insert(async_runners, function()
      self:_run_spec(spec, tree, args, adapter_id, adapter, results_callback)
    end)
  end
  local root = tree:root():data().path
  if args.concurrent ~= false and config.projects[root].running.concurrent then
    nio.gather(async_runners)
  else
    for _, runner in ipairs(async_runners) do
      runner()
    end
  end
end

---@param spec neotest.RunSpec
---@param adapter neotest.Adapter
function TestRunner:_run_spec(spec, tree, args, adapter_id, adapter, results_callback)
  if type(spec.strategy) == "function" then
    args = vim.tbl_extend("keep", { strategy = spec.strategy }, args)
  else
    spec.strategy =
      vim.tbl_extend("force", spec.strategy or {}, config.strategies[args.strategy] or {})
  end
  spec.env = vim.tbl_extend("force", spec.env or {}, args.env or {})
  spec.cwd = args.cwd or spec.cwd
  if vim.tbl_isempty(spec.env or {}) then
    spec.env = nil
  end
  local position = tree:data()
  local context = {
    position = position,
    adapter = adapter,
  }

  local proc_key = self:_create_process_key(adapter_id, position.id)

  local stream_processor = spec.stream
    and function(stream)
      for stream_results in spec.stream(stream) do
        results_callback(tree, stream_results)
      end
    end
  local process_result = self._processes:run(proc_key, spec, args, stream_processor, context)

  local results = adapter.results(spec, process_result, tree)

  results_callback(tree, results, process_result.output)
end

function TestRunner:_run_broken_down_tree(tree, args, adapter_id, adapter, results_callback)
  local position = tree:data()
  local function run_pos_types(pos_type)
    local async_runners = {}
    for _, node in tree:iter_nodes() do
      if node:data().type == pos_type then
        table.insert(async_runners, function()
          self:_run_tree(node, args, adapter_id, adapter, results_callback)
        end)
      end
    end
    if #async_runners == 0 then
      return {}
    end
    local root = tree:root():data().path
    if args.concurrent ~= false and config.projects[root].running.concurrent then
      nio.gather(async_runners)
    else
      for _, runner in ipairs(async_runners) do
        runner()
      end
    end
  end

  if position.type == "dir" then
    logger.warn(("%s doesn't support running directories, attempting files"):format(adapter.name))
    return run_pos_types("file")
  elseif position.type ~= "test" then
    logger.warn(("%s doesn't support running %ss"):format(adapter.name, position.type))
    return run_pos_types("test")
  end
  error(("%s returned no data to run tests"):format(adapter.name))
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
---@param tree neotest.Tree
---@param results table<string, neotest.Result>
---@param partial? boolean
function TestRunner:_missing_results(tree, results, partial)
  local new_results = {}
  local results_proxy = setmetatable({}, {
    __index = function(_, key)
      return new_results[key] or results[key]
    end,
    __newindex = function(_, key, value)
      new_results[key] = value
    end,
  })
  local root = tree:data()
  local missing_tests = {}

  local all_position_ids = {}
  for _, pos in tree:iter() do
    all_position_ids[pos.id] = true
  end

  local function propagate_result_upwards(node)
    for parent in node:iter_parents() do
      local parent_pos = parent:data()
      if not all_position_ids[parent_pos.id] then
        return
      end

      local parent_result = results_proxy[parent_pos.id]
      local pos_result = results_proxy[node:data().id]
      if not parent_result then
        parent_result = { status = "passed" }
      end

      if pos_result.status ~= "skipped" and parent_result.status == "passed" then
        parent_result.status = pos_result.status
      end

      results_proxy[parent_pos.id] = parent_result
    end
  end

  for _, node in tree:iter_nodes() do
    local pos = node:data()
    if results_proxy[pos.id] then
      propagate_result_upwards(node)
    elseif pos.type == "test" then
      missing_tests[#missing_tests + 1] = pos.id
    end
  end

  if partial then
    for _, test_id in ipairs(missing_tests) do
      local test = tree:get_key(test_id)
      if test then
        for parent in test:iter_parents() do
          results_proxy[parent:data().id] = nil
        end
      end
    end
  else
    local root_result = results_proxy[root.id]
    for _, node in tree:iter_nodes() do
      local pos = node:data()
      if pos.type == "file" and not results_proxy[pos.id] then
        -- Files not being present means that they were skipped (probably)
        results_proxy[pos.id] = { status = "skipped" }
      elseif pos.type ~= "dir" and not results_proxy[pos.id] and root_result then
        -- Tests and namespaces not being present means that they failed to even start, count as root result
        results_proxy[pos.id] = { status = root_result.status }
      end
    end
  end

  return new_results
end

return function(processes)
  return TestRunner:new(processes)
end
