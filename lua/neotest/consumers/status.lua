local async = require("neotest.async")
local consumer_name = "neotest-status"
local config = require("neotest.config")

---@param client neotest.Client
local function init(client)
  vim.fn.sign_define(
    "neotest_passed",
    { text = config.icons.passed, texthl = config.highlights.passed }
  )
  vim.fn.sign_define(
    "neotest_skipped",
    { text = config.icons.skipped, texthl = config.highlights.skipped }
  )
  vim.fn.sign_define(
    "neotest_failed",
    { text = config.icons.failed, texthl = config.highlights.failed }
  )
  vim.fn.sign_define(
    "neotest_running",
    { text = config.icons.running, texthl = config.highlights.running }
  )

  local file_adapters = {}

  local function render_files(files)
    for _, file_path in pairs(files) do
      local adapter_id = file_adapters[file_path]
      local results = client:get_results(adapter_id)
      async.fn.sign_unplace(consumer_name, { buffer = file_path })
      local tree = client:get_position(file_path, { adapter = adapter_id })
      for _, pos in tree:iter() do
        if pos.type ~= "file" then
          local icon
          if client:is_running(pos.id, { adapter = adapter_id }) then
            icon = "neotest_running"
          elseif results[pos.id] then
            local result = results[pos.id]
            icon = "neotest_" .. result.status
          end
          if icon then
            async.fn.sign_place(
              0,
              consumer_name,
              icon,
              pos.path,
              { lnum = pos.range[1] + 1, priority = 1000 }
            )
          end
        end
      end
    end
  end

  client.listeners.discover_positions[consumer_name] = function(adapter_id, tree)
    local file_path = tree:data().id
    if tree:data().type == "file" and async.fn.bufnr(file_path) ~= -1 then
      file_adapters[file_path] = adapter_id
      render_files({ file_path })
    end
  end

  client.listeners.run[consumer_name] = function(adapter_id, _, position_ids)
    local files = {}
    for _, pos_id in pairs(position_ids) do
      local node = client:get_position(pos_id, { adapter = adapter_id })
      if node then
        local file = node:data().path
        if file_adapters[file] then
          files[file] = files[file] or {}
          table.insert(files[file], pos_id)
        end
      end
    end
    render_files(vim.tbl_keys(files))
  end

  client.listeners.results[consumer_name] = function(adapter_id, results)
    local files = {}
    for pos_id, _ in pairs(results) do
      local node = client:get_position(pos_id, { adapter = adapter_id })
      if node then
        local file = node:data().path
        if file_adapters[file] then
          files[file] = true
        end
      end
    end
    render_files(vim.tbl_keys(files))
  end

  client.listeners.test_file_focused[consumer_name] = function(adapter_id, file_path)
    if not file_adapters[file_path] then
      file_adapters[file_path] = adapter_id
    end
    render_files({ file_path })
  end
end

---@tag neotest.status
---@brief [[
--- A consumer that displays the results of tests as signs beside their declaration.
--- This consumer is completely passive and so has no interface.
---@brief ]]
--
local neotest = {}
neotest.status = {}
neotest.status = setmetatable(neotest.status, {
  __call = function(_, ...)
    return init(...)
  end,
})

return neotest.status
