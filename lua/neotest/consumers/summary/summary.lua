local lib = require("neotest.lib")
local logger = require("neotest.logging")
local config = require("neotest.config")
local Canvas = require("neotest.consumers.summary.canvas")
local SummaryComponent = require("neotest.consumers.summary.component")
local async = require("neotest.async")

local events = {
  open = "NeotestSummaryOpen",
  close = "NeotestSummaryClose",
}

---@class neotest.Summary
---@field client neotest.Client
---@field win neotest.PersistentWindow
---@field components table<string, SummaryComponent>
---@field render_cond table
---@field focused? string
---@field running boolean
local Summary = {}

function Summary:new(client)
  self.__index = self
  return setmetatable({
    client = client,
    win = lib.persistent_window.panel({
      name = "Neotest Summary",
      open = "botright vsplit | vertical resize 50",
      bufopts = {
        filetype = "neotest-summary",
      },
    }),
    components = {},
    render_cond = async.control.Condvar.new(),
    focused = nil,
    running = false,
  }, self)
end

function Summary:open()
  self.win:open()
  vim.api.nvim_exec_autocmds("User", { pattern = events.open })
end

function Summary:close()
  if not self.win:is_open() then
    return
  end
  self.win:close()
  vim.api.nvim_exec_autocmds("User", { pattern = events.close })
end

local pending_render = false
local all_expanded = {}

function Summary:render(expanded)
  if not self.win:is_open() then
    return
  end
  if not self.running then
    async.run(function()
      self:run()
    end)
  end
  local ready = self.client:has_started()
  if not ready then
    async.run(function()
      self.client:ensure_started()
      -- In case no tests are found, we re-render.
      -- Want to do async because otherwise the "No tests found" render will
      -- happen before the "Parsing tests" render
      vim.schedule(function()
        self:render()
      end)
    end)
  end
  for pos_id, _ in pairs(expanded or {}) do
    all_expanded[pos_id] = true
  end
  pending_render = true
  self.render_cond:notify_all()
end

function Summary:run()
  self.running = true
  xpcall(function()
    while true do
      if not pending_render then
        self.render_cond:wait()
      end
      pending_render = false
      local canvas = Canvas.new(config.summary)
      if not self.client:has_started() then
        canvas:write("Parsing tests")
      else
        local cwd = vim.loop.cwd()
        for _, adapter_id in ipairs(self.client:get_adapters()) do
          local tree = assert(self.client:get_position(nil, { adapter = adapter_id }))
          canvas:write(
            vim.split(adapter_id, ":", { trimempty = true })[1] .. "\n",
            { group = config.highlights.adapter_name }
          )
          if tree:data().path ~= cwd then
            local root_dir = async.fn.fnamemodify(tree:data().path, ":.")
            canvas:write(root_dir .. "\n", { group = config.highlights.dir })
          end
          self.components[adapter_id] = self.components[adapter_id]
            or SummaryComponent(self.client, adapter_id)
          if config.summary.animated then
            pending_render = self.components[adapter_id]:render(
              canvas,
              tree,
              all_expanded,
              self.focused
            ) or pending_render
          else
            self.components[adapter_id]:render(canvas, tree, all_expanded, self.focused)
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
      local rendered, err = pcall(canvas.render_buffer, canvas, self.win:buffer())
      if not rendered then
        logger.error("Couldn't render buffer", err)
      end
      async.api.nvim_exec("redraw", false)
      async.util.sleep(100)
    end
  end, function(msg)
    logger.error("Error in summary consumer", debug.traceback(msg, 2))
  end)
  self.running = false
end

function Summary:expand(pos_id, recursive, focus)
  local tree = self.client:get_position(pos_id)
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
    self.focused = pos_id
  end
  self:render(expanded)
end

return function(client)
  return Summary:new(client)
end
