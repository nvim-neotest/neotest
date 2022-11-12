local lib = require("neotest.lib")
local logger = require("neotest.logging")
local config = require("neotest.config")
local Canvas = require("neotest.consumers.summary.canvas")
local SummaryComponent = require("neotest.consumers.summary.component")
local async = require("neotest.async")

---@private
---@type neotest.Client
local client
local buf_name = "Neotest Summary"
local summary_buf
local au_open = "NeotestSummaryOpen"
local au_close = "NeotestSummaryClose"

local function create_buf()
  if summary_buf then
    return summary_buf
  end

  summary_buf = async.api.nvim_create_buf(false, true)
  async.api.nvim_buf_set_option(summary_buf, "modifiable", false)
  async.api.nvim_buf_set_name(summary_buf, buf_name)
  return summary_buf
end

local function is_open()
  return summary_buf and async.fn.bufwinnr(summary_buf) ~= -1
end

local function open_window(buf)
  local cur_win = async.api.nvim_get_current_win()
  vim.cmd([[botright vsplit | vertical resize 50]])
  local win = async.api.nvim_get_current_win()
  async.api.nvim_win_set_buf(win, buf)
  async.api.nvim_set_current_win(cur_win)
  async.api.nvim_buf_set_option(summary_buf, "filetype", "neotest-summary")
  vim.api.nvim_exec_autocmds("User", { pattern = au_open })
end

local components = {}

local render_cond = async.control.Condvar.new()

local focused
local pending_render = false
local all_expanded = {}
local function render(expanded)
  if not is_open() then
    return
  end
  local ready = client:has_started()
  if not ready then
    async.run(function()
      client:ensure_started()
      -- In case no tests are found, we re-render.
      -- Want to do async because otherwise the "No tests found" render will
      -- happen before the "Parsing tests" render
      vim.schedule(render)
    end)
  end
  for pos_id, _ in pairs(expanded or {}) do
    all_expanded[pos_id] = true
  end
  pending_render = true
  render_cond:notify_all()
end

async.run(function()
  xpcall(function()
    while true do
      if not pending_render then
        render_cond:wait()
      end
      pending_render = false
      local canvas = Canvas.new(config.summary)
      if not client:has_started() then
        canvas:write("Parsing tests")
      else
        local cwd = vim.loop.cwd()
        for _, adapter_id in ipairs(client:get_adapters()) do
          local tree = client:get_position(nil, { adapter = adapter_id })
          canvas:write(
            vim.split(adapter_id, ":", { trimempty = true })[1] .. "\n",
            { group = config.highlights.adapter_name }
          )
          if tree:data().path ~= cwd then
            local root_dir = async.fn.fnamemodify(tree:data().path, ":.")
            canvas:write(root_dir .. "\n", { group = config.highlights.dir })
          end
          components[adapter_id] = components[adapter_id] or SummaryComponent(client, adapter_id)
          if config.summary.animated then
            pending_render = components[adapter_id]:render(canvas, tree, all_expanded, focused)
              or pending_render
          else
            components[adapter_id]:render(canvas, tree, all_expanded, focused)
          end
          all_expanded = {}
          canvas:write("\n")
        end
        if canvas:length() > 1 then
          canvas:remove_line()
          canvas:remove_line()
        else
          canvas:write("No tests found")
        end
      end
      local rendered, err = pcall(canvas.render_buffer, canvas, summary_buf)
      if not rendered then
        logger.error("Couldn't render buffer", err)
      end
      async.api.nvim_exec("redraw", false)
      async.util.sleep(100)
    end
  end, function(msg)
    logger.error("Error in summary consumer", debug.traceback(msg, 2))
  end)
end)

local function expand(pos_id, recursive, focus)
  local tree = client:get_position(pos_id)
  if not tree then
    return
  end
  local expanded = {}
  if recursive then
    for _, node in tree:iter_nodes() do
      if #node:children() > 0 then
        expanded[node:data().id] = true
      end
    end
  else
    expanded[pos_id] = true
  end
  for parent in tree:iter_parents() do
    expanded[parent:data().id] = true
  end
  if focus then
    focused = pos_id
  end
  render(expanded)
end

local listener = function()
  render()
end

local function init()
  client.listeners.discover_positions = listener
  client.listeners.run = listener

  client.listeners.results = function(adapter_id, results)
    if not config.summary.expand_errors then
      render()
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
    render(expanded)
  end

  if config.summary.follow then
    client.listeners.test_file_focused = function(_, file_path)
      expand(file_path, true)
    end
    client.listeners.test_focused = function(_, pos_id)
      expand(pos_id, false, true)
    end
  end
end

local function open()
  create_buf()
  open_window(summary_buf)
end

local function close()
  if is_open() then
    local win = async.fn.win_getid(async.fn.bufwinnr(summary_buf))
    async.api.nvim_win_close(win, true)
    vim.api.nvim_exec_autocmds("User", { pattern = au_close })
  end
end

local neotest = {}

---@toc_entry Summary Consumer
---@text
--- A consumer that displays the structure of the test suite, along with results and
--- allows running tests.
---@seealso |neotest.Config.summary.mappings| for all mappings in the summary window
neotest.summary = {}

neotest.summary.render = render

--- Open the summary window
--- >
---   lua require("neotest").summary.open()
--- <
function neotest.summary.open()
  if is_open() then
    return
  end
  open()
  render()
end

--- Close the summary window
--- >
---   lua require("neotest").summary.close()
--- <
function neotest.summary.close()
  close()
end

---Toggle the summary window
---
--->
---  lua require("neotest").summary.toggle()
---<
function neotest.summary.toggle()
  async.run(function()
    if is_open() then
      close()
    else
      open()
      render()
    end
  end)
end

--- Run all marked positions
---@param args table
---
---@field adapter string Adapter ID, if not given all adapters are used
---@field strategy string|neotest.Strategy Strategy to run commands with
---@field extra_args string[] Extra arguments for test command
---@field env table<string, string> Extra environment variables to add to the
--- environment of tests
function neotest.summary.run_marked(args)
  args = args or {}
  for adapter_id, component in pairs(components) do
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

--- Clear all marked positions
---@param args table
---
---@field adapter string Adapter ID, if not given all adapters are used
function neotest.summary.clear_marked(args)
  args = args or {}
  for adapter_id, component in pairs(components) do
    if not args.adapter or args.adapter == adapter_id then
      component.marked = {}
    end
  end
  render()
end

--- Set the target for an adapter tree
---@param adapter_id string
---@param position_id string|nil Position ID to target, nil to reset target
function neotest.summary.target(adapter_id, position_id)
  local component = components[adapter_id]
  if not component then
    lib.notify(("No tree found for adapter %s"):format(adapter_id))
  end
  component.target = position_id
  render()
end

function neotest.summary.expand(pos_id, recursive)
  async.run(function()
    expand(pos_id, recursive)
  end)
end

neotest.summary = setmetatable(neotest.summary, {
  __call = function(_, client_)
    client = client_
    init()
    return neotest.summary
  end,
})

return neotest.summary
