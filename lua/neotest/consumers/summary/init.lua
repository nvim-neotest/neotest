local lib = require("neotest.lib")
local nio = require("nio")
local Summary = require("neotest.consumers.summary.summary")
local config = require("neotest.config")

---@type neotest.Summary
---@private
local summary

local group = vim.api.nvim_create_augroup("FollowSummaryOnOpen", { clear = true })

---@param client neotest.Client
---@private
local function init(client)
  summary = Summary(client)

  local listener = function()
    summary:render()
  end

  client.listeners.discover_positions = listener
  client.listeners.run = listener

  client.listeners.results = function(adapter_id, results)
    if not config.summary.expand_errors then
      summary:render()
      return
    end
    local expanded = {}
    for pos_id, result in pairs(results) do
      if
        result.status == "failed"
        and client:get_position(pos_id, { adapter = adapter_id })
        and #client:get_position(pos_id, { adapter = adapter_id }):children() > 0
      then
        expanded[pos_id] = true
      end
    end
    summary:render(expanded)
  end

  client.listeners.starting = function()
    summary:set_starting()
  end

  client.listeners.started = function()
    summary:set_started()
  end

  if config.summary.follow then
    local function now_or_on_summary_open(func)
      if summary.win:is_open() then
        func()
      else
        vim.api.nvim_create_autocmd("User", {
          pattern = "NeotestSummaryOpen",
          group = group,
          callback = func,
          once = true,
        })
      end
    end

    client.listeners.test_file_focused = function(_, file_path)
      now_or_on_summary_open(function()
        summary:expand(file_path, true)
      end)
    end
    client.listeners.test_focused = function(_, pos_id)
      now_or_on_summary_open(function()
        summary:expand(pos_id, false, true)
      end)
    end
  end
end

local neotest = {}

---@toc_entry Summary Consumer
---@text
--- A consumer that displays the structure of the test suite, along with results and
--- allows running tests.
---@seealso |neotest.Config.summary.mappings| for all mappings in the summary window
---@class neotest.consumers.summary
neotest.summary = {}

---@private
neotest.summary.render = function(positions)
  summary:render(positions)
end

--- Open the summary window
--- ```vim
---   lua require("neotest").summary.open()
--- ```
function neotest.summary.open()
  if summary.win:is_open() then
    return
  end
  summary:open()
  summary:render()
end

--- Close the summary window
--- ```vim
---   lua require("neotest").summary.close()
--- ```
function neotest.summary.close()
  summary:close()
end

---Toggle the summary window
---
--- ```vim
---  lua require("neotest").summary.toggle()
--- ```
function neotest.summary.toggle()
  nio.run(function()
    if summary.win:is_open() then
      summary:close()
    else
      summary:open()
      summary:render()
    end
  end)
end

---@class neotest.summmary.RunMarkedArgs : neotest.run.RunArgs

--- Run all marked positions
---@param args? neotest.summmary.RunMarkedArgs
function neotest.summary.run_marked(args)
  args = args or {}
  for adapter_id, component in pairs(summary.components) do
    if not args.adapter or args.adapter == adapter_id then
      for pos_id, marked in pairs(component.marked) do
        if marked then
          require("neotest").run.run(
            vim.tbl_extend("keep", { pos_id, adapter = component.adapter_id }, args)
          )
        end
      end
    end
  end
end

--- Return a table<adapter id, position_id[]> of all marked positions
--- @return table<string, string[]>
function neotest.summary.marked()
  local all_marked = {}
  for adapter_id, component in pairs(summary.components) do
    local adapter_marked = {}
    local has_marked = false
    for pos_id, marked in pairs(component.marked) do
      if marked then
        table.insert(adapter_marked, pos_id)
        has_marked = true
      end
    end
    if has_marked then
      all_marked[adapter_id] = adapter_marked
    end
  end
  return all_marked
end

---@class neotest.summary.ClearMarkedArgs
---@field adapter? string Adapter ID, if not given all adapters are cleared

--- Clear all marked positions
---@param args? neotest.summary.ClearMarkedArgs
function neotest.summary.clear_marked(args)
  args = args or {}
  for adapter_id, component in pairs(summary.components) do
    if not args.adapter or args.adapter == adapter_id then
      component.marked = {}
    end
  end
  summary:render()
end

--- Set the target for an adapter tree
---@param adapter_id string
---@param position_id string|nil Position ID to target, nil to reset target
function neotest.summary.target(adapter_id, position_id)
  local component = summary.components[adapter_id]
  if not component then
    lib.notify(("No tree found for adapter %s"):format(adapter_id))
  end
  component.target = position_id
  summary:render()
end

function neotest.summary:expand(pos_id, recursive)
  nio.run(function()
    summary:expand(pos_id, recursive)
  end)
end

neotest.summary = setmetatable(neotest.summary, {
  __call = function(_, client)
    init(client)
    return neotest.summary
  end,
})

return neotest.summary
