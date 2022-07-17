local async = require("neotest.async")
local config = require("neotest.config")
local icons = config.icons
local hi = config.highlights
local lib = require("neotest.lib")

---@class SummaryComponent
---@field client neotest.InternalClient
---@field expanded_positions table
---@field child_components table<number, SummaryComponent>
---@field marked table<string, boolean>
---@field adapter_id integer
---@field target string?
local SummaryComponent = {}

function SummaryComponent:new(client, adapter_id)
  local elem = {
    client = client,
    target = nil,
    expanded_positions = {},
    adapter_id = adapter_id,
    marked = {},
  }
  setmetatable(elem, self)
  self.__index = self
  return elem
end

function SummaryComponent:toggle_reference(pos_id)
  self.expanded_positions[pos_id] = not self.expanded_positions[pos_id]
end

local async_func = function(f)
  return function()
    async.run(f)
  end
end

---@param canvas Canvas
---@param tree neotest.Tree
function SummaryComponent:render(canvas, tree, expanded, focused, indent)
  if self.target then
    tree = tree:get_key(self.target)
    if not tree then
      return
    end
    canvas:add_mapping("clear_target", function()
      require("neotest").summary.target(self.adapter_id)
    end)
    canvas:write(tree:data().name .. "\n", { group = config.highlights.target })
  end
  self:_render(canvas, tree, expanded, focused, indent)
end

function SummaryComponent:_render(canvas, tree, expanded, focused, indent)
  indent = indent or ""
  local children = tree:children()
  local neotest = require("neotest")
  for index, node in pairs(children) do
    local is_last_child = index == #children
    local position = node:data()

    if expanded[position.id] then
      self.expanded_positions[position.id] = true
    end

    local node_prefix = indent .. (is_last_child and icons.final_child_prefix or icons.child_prefix)
    local chid_indent = indent .. (is_last_child and icons.final_child_indent or icons.child_indent)
    if #node_prefix > 0 then
      canvas:write(node_prefix, { group = hi.indent })
    end
    local expansion_icon
    local expandable = #node:children() > 0
    if not expandable then
      expansion_icon = icons.non_collapsible
    elseif self.expanded_positions[position.id] then
      expansion_icon = icons.expanded
    else
      expansion_icon = icons.collapsed
    end
    canvas:write(expansion_icon, { group = config.highlights.expand_marker })

    if expandable then
      canvas:add_mapping(
        "expand",
        async_func(function()
          self:toggle_reference(position.id)
          neotest.summary.render()
        end)
      )

      canvas:add_mapping(
        "expand_all",
        async_func(function()
          local positions = {}
          local root_type = position.type
          --  Don't want to load all files under dir to prevent memory issues
          if root_type == "dir" then
            for _, pos in node:iter() do
              if pos.type == "dir" then
                positions[pos.id] = true
              end
            end
          else
            for _, pos in
              self.client:get_position(position.id, { adapter = self.adapter_id }):iter()
            do
              positions[pos.id] = true
            end
          end
          neotest.summary.render(positions)
        end)
      )

      canvas:add_mapping("target", function()
        neotest.summary.target(self.adapter_id, position.id)
      end)
    end
    canvas:add_mapping("clear_target", function()
      neotest.summary.target(self.adapter_id)
    end)
    if position.type ~= "dir" then
      canvas:add_mapping("jumpto", function()
        local buf = vim.fn.bufadd(position.path)
        -- Fails on swap conflict
        pcall(vim.fn.bufload, buf)
        vim.api.nvim_buf_set_option(buf, "buflisted", true)
        if position.type == "file" then
          lib.ui.open_buf(buf)
        else
          lib.ui.open_buf(buf, position.range[1], position.range[2])
        end
      end)
    end
    canvas:add_mapping(
      "attach",
      async_func(function()
        neotest.run.attach(position.id, { adapter = self.adapter_id })
      end)
    )
    canvas:add_mapping(
      "output",
      async_func(function()
        neotest.output.open({ position_id = position.id, adapter = self.adapter_id })
      end)
    )

    canvas:add_mapping(
      "short",
      async_func(function()
        neotest.output.open({ position_id = position.id, short = true, adapter = self.adapter_id })
      end)
    )

    canvas:add_mapping("stop", function()
      neotest.run.stop({ position.id, adapter = self.adapter_id })
    end)

    canvas:add_mapping("run", function()
      neotest.run.run({ position.id, adapter = self.adapter_id })
    end)

    canvas:add_mapping("mark", function()
      self.marked[position.id] = not self.marked[position.id]
      neotest.summary.render()
    end)

    canvas:add_mapping("run_marked", function()
      neotest.summary.run_marked({ adapter = self.adapter_id })
    end)

    canvas:add_mapping("clear_marked", function()
      neotest.summary.clear_marked({ adapter = self.adapter_id })
    end)

    local state_icon, state_icon_group = self:_state_icon(position)
    canvas:write(" " .. state_icon .. " ", { group = state_icon_group })

    local name_groups = { config.highlights[position.type] }
    if focused == position.id then
      table.insert(name_groups, hi.focused)
      canvas:position_cursor()
    end
    if self.marked[position.id] then
      table.insert(name_groups, hi.marked)
    end
    canvas:write(position.name .. "\n", { group = name_groups })

    if self.expanded_positions[position.id] then
      self:_render(canvas, node, expanded, focused, chid_indent)
    end
  end
end

function SummaryComponent:_state_icon(position)
  local result = self.client:get_results(self.adapter_id)[position.id]
  if not result then
    if self.client:is_running(position.id, { adapter = self.adapter_id }) then
      return config.icons.running, config.highlights.running
    end
    return config.icons.unknown, config.highlights.unknown
  end
  return config.icons[result.status], config.highlights[result.status]
end

---@return SummaryComponent
return function(client, adapter_id)
  return SummaryComponent:new(client, adapter_id)
end
