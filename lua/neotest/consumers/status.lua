local async = require("plenary.async")
local consumer_name = "neotest-status"
local config = require("neotest.config")

---@param client NeotestClient
return function(client)
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

  local tracked_files = {}

  local function render_files(files)
    local results = client:get_results()
    for _, file_path in pairs(files) do
      async.fn.sign_unplace(consumer_name, { buffer = file_path })
      local tree = client:get_position(file_path)
      for _, pos in tree:iter() do
        if pos.type ~= "file" then
          local icon
          if client:is_running(pos.id) then
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

  client.listeners.discover_positions[consumer_name] = function(tree)
    local file_path = tree:data().id
    if tree:data().type == "file" and async.fn.bufnr(file_path) ~= -1 then
      tracked_files[file_path] = true
      render_files({ file_path })
    end
  end

  client.listeners.run[consumer_name] = function(_, position_ids)
    local files = {}
    for _, pos_id in pairs(position_ids) do
      local node = client:get_position(pos_id)
      if node then
        local file = node:data().path
        if tracked_files[file] then
          files[file] = files[file] or {}
          table.insert(files[file], pos_id)
        end
      end
    end
    render_files(vim.tbl_keys(files))
  end

  client.listeners.results[consumer_name] = function(results)
    local files = {}
    for pos_id, _ in pairs(results) do
      local node = client:get_position(pos_id)
      if node then
        local file = node:data().path
        if tracked_files[file] then
          files[file] = true
        end
      end
    end
    render_files(vim.tbl_keys(files))
  end
end
