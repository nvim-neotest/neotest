local lib = require("neotest.lib")
local types = require("neotest.types")
local logger = require("neotest.logging")
local config = require("neotest.config")
local Canvas = require("neotest.consumers.summary.canvas")
local SummaryComponent = require("neotest.consumers.summary.component")
local nio = require("nio")

local events = {
  open = "NeotestSummaryOpen",
  close = "NeotestSummaryClose",
}

---@class neotest.Summary
---@field client neotest.Client
---@field win neotest.PersistentWindow
---@field components table<string, SummaryComponent>
---@field render_ready nio.control.Event
---@field focused? string
---@field running boolean
local Summary = {}

function Summary:new(client)
  self.__index = self
  return setmetatable({
    client = client,
    win = lib.persistent_window.panel({
      name = "Neotest Summary",
      open = config.summary.open,
      bufopts = {
        filetype = "neotest-summary",
      },
    }),
    components = {},
    render_ready = nio.control.event(),
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

local all_expanded = {}

---@param canvas neotest.summary.Canvas
---@param adapter_id string
function Summary:_write_header(canvas, adapter_id, tree)
  canvas:write(
    vim.split(adapter_id, ":", { trimempty = true })[1] .. " ",
    { group = config.highlights.adapter_name }
  )

  if config.summary.count then
    local status_counts = {
      test = 0,
      running = 0,
      passed = 0,
      failed = 0,
      skipped = 0,
    }
    local results = self.client:get_results(adapter_id)

    for _, pos in tree:iter() do
      if pos.type == "test" then
        status_counts.test = status_counts.test + 1

        local result = results[pos.id]

        if result and status_counts[result.status] ~= nil then
          status_counts[result.status] = status_counts[result.status] + 1
        elseif self.client:is_running(pos.id, { adapter = adapter_id }) then
          status_counts.running = status_counts.running + 1
        end
      end
    end

    for _, status in ipairs({ "test", "passed", "failed", "running", "skipped" }) do
      canvas:write(
        config.icons[status] .. " " .. tostring(status_counts[status]) .. " ",
        { group = config.highlights[status] or config.highlights.namespace }
      )
    end
  end
  canvas:write("\n")

  local cwd = vim.loop.cwd()
  if tree:data().path ~= cwd then
    local root_dir = nio.fn.fnamemodify(tree:data().path, ":.")
    canvas:write(root_dir .. "\n", { group = config.highlights.dir })
  end
end

function Summary:render(expanded)
  if not self.win:is_open() then
    return
  end
  if not self.running then
    nio.run(function()
      self:run()
    end)
  end
  for pos_id, _ in pairs(expanded or {}) do
    all_expanded[pos_id] = true
  end
  self.render_ready.set()
end

function Summary:set_starting()
  self._starting = true
end

function Summary:set_started()
  self._started = true
end

function Summary:run()
  if self.running then
    return
  end
  self.running = true
  xpcall(function()
    while true do
      self.render_ready.wait()
      self.render_ready.clear()
      local canvas = Canvas.new(config.summary)
      if self._starting then
        for _, adapter_id in ipairs(self.client:get_adapters()) do
          local tree = assert(self.client:get_position(nil, { adapter = adapter_id }))
          self:_write_header(canvas, adapter_id, tree)
          self.components[adapter_id] = self.components[adapter_id]
            or SummaryComponent(self.client, adapter_id)
          if config.summary.animated then
            if self.components[adapter_id]:render(canvas, tree, all_expanded, self.focused) then
              self.render_ready.set()
            end
          else
            self.components[adapter_id]:render(canvas, tree, all_expanded, self.focused)
          end
          all_expanded = {}
          canvas:write("\n")
        end
      else
        nio.run(function()
          self.client:get_adapters()
        end)
      end
      if canvas:length() > 1 then
        canvas:remove_line()
        canvas:remove_line()
      elseif not self._started then
        canvas:write("Parsing tests")
      else
        canvas:write("No tests found")
      end
      local rendered, err = pcall(canvas.render_buffer, canvas, self.win:buffer())
      if not rendered then
        logger.error("Couldn't render buffer", err)
      end
      nio.api.nvim_exec2("redraw", {})
      nio.sleep(100)
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
