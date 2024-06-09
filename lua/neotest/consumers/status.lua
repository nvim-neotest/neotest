local nio = require("nio")
local sign_group = "neotest-status"
local config = require("neotest.config")

local function init(client)
  local statuses = {
    passed = { text = config.icons.passed, texthl = config.highlights.passed },
    skipped = { text = config.icons.skipped, texthl = config.highlights.skipped },
    failed = { text = config.icons.failed, texthl = config.highlights.failed },
    running = { text = config.icons.running, texthl = config.highlights.running },
  }
  for status, conf in pairs(statuses) do
    nio.fn.sign_define("neotest_" .. status, conf)
  end

  local namespace = nio.api.nvim_create_namespace(sign_group)

  local function place_sign(buf, pos, adapter_id, results)
    local status
    if results[pos.id] then
      local result = results[pos.id]
      status = result.status
    elseif client:is_running(pos.id, { adapter = adapter_id }) then
      status = "running"
    end
    if not status then
      return
    end
    if config.status.signs and nio.api.nvim_buf_is_valid(buf) and nio.fn.buflisted(buf) ~= 0 then
      local line_count = vim.api.nvim_buf_line_count(buf)
      local line_number = pos.range[1] + 1
      if line_number <= line_count then
        nio.fn.sign_place(0, sign_group, "neotest_" .. status, buf, {
          lnum = line_number,
          priority = 1000,
        })
      end
    end
    if config.status.virtual_text and nio.api.nvim_buf_is_valid(buf) then
      local line_count = vim.api.nvim_buf_line_count(buf)
      local line_number = pos.range[1]
      if line_number < line_count then
        nio.api.nvim_buf_set_extmark(buf, namespace, line_number, 0, {
          virt_text_pos = "eol",
          virt_text = {
            { statuses[status].text .. " ", statuses[status].texthl },
          },
        })
      end
    end
  end

  local function render_files(adapter_id, files)
    for _, file_path in pairs(files) do
      local bufnr = nio.fn.bufnr(file_path)
      if nio.fn.buflisted(bufnr) ~= 0 and nio.api.nvim_buf_is_valid(bufnr) then
        local results = client:get_results(adapter_id)
        nio.fn.sign_unplace(sign_group, { buffer = bufnr })
        nio.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
        local tree = client:get_position(file_path, { adapter = adapter_id })
        if not tree then
          return
        end
        for _, node in tree:iter_nodes() do
          local pos = node:data()
          if pos.range ~= nil and pos.type ~= "file" then
            place_sign(bufnr, pos, adapter_id, results)
          end
        end
      end
    end
  end

  client.listeners.discover_positions = function(adapter_id, tree)
    local file_path = tree:data().id
    if tree:data().type == "file" then
      render_files(adapter_id, { file_path })
    end
  end

  client.listeners.run = function(adapter_id, _, position_ids)
    local files = {}
    for _, pos_id in pairs(position_ids) do
      local node = client:get_position(pos_id, { adapter = adapter_id })
      if node and node:data().type ~= "dir" then
        local file = node:data().path
        files[file] = files[file] or {}
        table.insert(files[file], pos_id)
      end
    end
    render_files(adapter_id, vim.tbl_keys(files))
  end

  client.listeners.results = function(adapter_id, results)
    local files = {}
    for pos_id, _ in pairs(results) do
      local node = client:get_position(pos_id, { adapter = adapter_id })
      if node and node:data().type ~= "dir" then
        local file = node:data().path
        files[file] = true
      end
    end
    render_files(adapter_id, vim.tbl_keys(files))
  end

  client.listeners.test_file_focused = function(adapter_id, file_path)
    render_files(adapter_id, { file_path })
  end
end

local neotest = {}
---@toc_entry Status Consumer
---@text
--- A consumer that displays the results of tests as signs beside their declaration.
--- This consumer is completely passive and so has no interface.
---@class neotest.consumers.status
neotest.status = {}

neotest.status = setmetatable(neotest.status, {
  __call = function(_, ...)
    return init(...)
  end,
})

return neotest.status
