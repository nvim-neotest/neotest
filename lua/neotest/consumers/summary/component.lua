local async = require("plenary.async")
local config = require("neotest.config")
local hi = config.highlights
local lib = require("neotest.lib")

---@class SummaryComponent
---@field client NeotestClient
---@field expanded_children table
---@field child_components table<number, SummaryComponent>
local SummaryComponent = {}

function SummaryComponent:new(client)
  local elem = {
    client = client,
    expanded_children = {},
    child_components = {},
  }
  setmetatable(elem, self)
  self.__index = self
  return elem
end

function SummaryComponent:toggle_reference(pos_id)
  self.expanded_children[pos_id] = not self.expanded_children[pos_id]
end

local async_func = function(f)
  return function()
    async.run(f)
  end
end

---@param render_state RenderState
---@param tree Tree
function SummaryComponent:render(render_state, tree, expanded, indent)
  indent = indent or ""
  for pos_id, _ in pairs(self.child_components) do
    if not tree:get_key(pos_id) then
      self.child_components[pos_id] = nil
    end
  end
  local root_pos = tree:data()
  local children = tree:children()
  if #children == 0 and (root_pos.type == "dir" or root_pos.type == "file") then
    self.client:update_positions(root_pos.id)
    children = self.client:get_position(root_pos.id):children()
  end
  for index, node in pairs(children) do
    local is_last_child = index == #children
    local position = node:data()

    if expanded[position.id] then
      self.expanded_children[position.id] = true
    end

    local node_indent = indent .. (is_last_child and "└ " or "│ ")
    local chid_indent = is_last_child and (indent .. "  ") or node_indent
    if #indent > 0 then
      render_state:write(node_indent, { group = hi.indent })
    end

    if position.type ~= "test" then
      render_state:add_mapping(
        "expand",
        async_func(function()
          self:toggle_reference(position.id)
          require("neotest").summary.render()
        end)
      )

      render_state:add_mapping(
        "expand_all",
        async_func(function()
          local positions = {}
          local root_type = position.type
          -- Don't want to load all files under dir to prevent memory issues
          if root_type == "dir" then
            for _, pos in node:iter() do
              if pos.type == "dir" then
                positions[pos.id] = true
              end
            end
          else
            for _, pos in node:iter() do
              positions[pos.id] = true
            end
          end
          require("neotest").summary.render(positions)
        end)
      )
    end
    if position.type ~= "dir" then
      render_state:add_mapping("jumpto", function()
        local buf = vim.fn.bufadd(position.path)
        vim.fn.bufload(buf)
        if position.type == "file" then
          lib.ui.open_buf(buf)
        else
          lib.ui.open_buf(buf, position.range[1], position.range[2])
        end
      end)
    end
    render_state:add_mapping(
      "attach",
      async_func(function()
        require("neotest").attach(position.id)
      end)
    )
    render_state:add_mapping(
      "output",
      async_func(function()
        require("neotest").output.open({ position_id = position.id })
      end)
    )

    render_state:add_mapping(
      "short",
      async_func(function()
        require("neotest").output.open({ position_id = position.id, short = true })
      end)
    )

    render_state:add_mapping("stop", function()
      require("neotest").stop(position.id)
    end)

    render_state:add_mapping("run", function()
      require("neotest").run(position.id)
    end)

    local prefix = self:_position_prefix(position)
    render_state:write(prefix, { group = config.highlights.expand_marker })

    local icon, icon_group = self:_position_icon(position)
    render_state:write(" " .. icon .. " ", { group = icon_group })

    render_state:write(position.name .. "\n", { group = config.highlights[position.type] })

    if self.expanded_children[position.id] then
      self:_get_child_component(position.id):render(render_state, node, expanded, chid_indent)
    end
  end
end

function SummaryComponent:_get_child_component(pos_id)
  if not self.child_components[pos_id] then
    self.child_components[pos_id] = SummaryComponent:new(self.client)
  end
  return self.child_components[pos_id]
end

function SummaryComponent:_position_prefix(position)
  if position.type == "test" then
    return " "
  end
  return config.icons[self.expanded_children[position.id] and "expanded" or "collapsed"]
end

function SummaryComponent:_position_icon(position)
  local result = self.client:get_results()[position.id]
  if not result then
    if self.client:is_running(position.id) then
      return config.icons.running, config.highlights.running
    end
    return config.icons.unknown, "Normal"
  end
  return config.icons[result.status], config.highlights[result.status]
end

---@return SummaryComponent
return function(client)
  return SummaryComponent:new(client)
end
