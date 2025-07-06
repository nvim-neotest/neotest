local nio = require("nio")
local config = require("neotest.config")
local icons = config.icons
local hi = config.highlights
local lib = require("neotest.lib")
local namespace = require("neotest.consumers.summary.canvas").namespace

---@class SummaryComponent
---@field client neotest.InternalClient
---@field expanded_positions table
---@field child_components table<number, SummaryComponent>
---@field marked table<string, boolean>
---@field adapter_id string
---@field target string?
---@field renders integer
local SummaryComponent = {}

function SummaryComponent:new(client, adapter_id)
  local elem = {
    client = client,
    target = nil,
    expanded_positions = {},
    adapter_id = adapter_id,
    marked = {},
    renders = 0,
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
    nio.run(f)
  end
end

---@param canvas neotest.summary.Canvas
---@param tree neotest.Tree
function SummaryComponent:render(canvas, tree, expanded, focused, indent)
  self.renders = self.renders + 1
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
  return self:_render(canvas, tree, expanded, focused, indent)
end

function SummaryComponent:_render(canvas, tree, expanded, focused, indent)
  indent = indent or ""
  local children = tree:children()
  local neotest = require("neotest")
  local has_running = false
  for index, node in ipairs(children) do
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
    canvas:add_mapping("next_failed", function()
      local row = vim.fn.line(".") - 1
      local extmarks = vim.api.nvim_buf_get_extmarks(
        0,
        namespace,
        { row + 1, 0 },
        { -1, 0 },
        { details = true }
      )
      for _, mark in ipairs(extmarks) do
        local _, mark_row, _, details = unpack(mark)
        if details.hl_group == config.highlights["failed"] then
          vim.fn.setpos(".", { 0, mark_row + 1, 1, 0 })
          return
        end
      end
    end)
    canvas:add_mapping("prev_failed", function()
      local row = vim.fn.line(".") - 1
      local extmarks = vim.api.nvim_buf_get_extmarks(
        0,
        namespace,
        { 0, 0 },
        { row, 0 },
        { details = true }
      )
      for _, mark in lib.func_util.reverse(extmarks) do
        local _, mark_row, _, details = unpack(mark)
        if details.hl_group == config.highlights["failed"] then
          vim.fn.setpos(".", { 0, mark_row + 1, 1, 0 })
          return
        end
      end
    end)

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
          local range = node:closest_value_for("range")
          lib.ui.open_buf(buf, range[1], range[2])
        end
      end)
    end
    canvas:add_mapping(
      "attach",
      async_func(function()
        neotest.run.attach(position.id, { adapter = self.adapter_id })
      end)
    )
    if neotest.watch then
      canvas:add_mapping(
        "watch",
        async_func(function()
          neotest.watch.toggle({ position.id, adapter = self.adapter_id })
          neotest.summary.render()
        end)
      )
    end
    canvas:add_mapping(
      "output",
      async_func(function()
        neotest.output.open({ position_id = position.id, adapter = self.adapter_id, enter = true })
      end)
    )

    canvas:add_mapping(
      "short",
      async_func(function()
        neotest.output.open({
          position_id = position.id,
          short = true,
          adapter = self.adapter_id,
          enter = true,
        })
      end)
    )

    canvas:add_mapping("stop", function()
      neotest.run.stop({ position.id, adapter = self.adapter_id })
    end)

    canvas:add_mapping("run", function()
      neotest.run.run({ position.id, adapter = self.adapter_id })
    end)

    canvas:add_mapping("debug", function()
      neotest.run.run({ position.id, adapter = self.adapter_id, strategy = "dap" })
    end)

    canvas:add_mapping("mark", function()
      self.marked[position.id] = not self.marked[position.id]
      neotest.summary.render()
    end)

    canvas:add_mapping("run_marked", function()
      neotest.summary.run_marked({ adapter = self.adapter_id })
    end)

    canvas:add_mapping("debug_marked", function()
      neotest.summary.run_marked({ adapter = self.adapter_id, strategy = "dap" })
    end)

    canvas:add_mapping("clear_marked", function()
      neotest.summary.clear_marked({ adapter = self.adapter_id })
    end)

    canvas:add_mapping(
      "help",
      async_func(function()
        local help_text = {}
        local width = 0
        for name, mapping in pairs(config.summary.mappings) do
          local mappings = type(mapping) == "table" and table.concat(mapping, ", ") or mapping
          local line = "(" .. name .. "): " .. mappings
          width = math.max(width, #line)
          table.insert(help_text, line)
        end

        table.insert(help_text, 1, "Mappings")
        width = math.max(width, #help_text[1])
        table.insert(help_text, 2, string.rep("=", width))

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
        local float = lib.ui.float.open({
          width = width,
          height = #help_text,
          buffer = buf,
          auto_close = true,
        })
        local win = float.win_id
        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>q<CR>", { noremap = true, silent = true })
      end)
    )

    local status = self:_get_status(position)
    has_running = has_running or status == "running"

    local state_icon, state_icon_group = self:_state_icon(status)

    if neotest.watch and neotest.watch.is_watching(position.id) then
      state_icon = config.icons.watching
    end

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
      has_running = self:_render(canvas, node, expanded, focused, chid_indent) or has_running
    end
  end
  return has_running
end

function SummaryComponent:_get_status(position)
  local result = self.client:get_results(self.adapter_id)[position.id]
  if result then
    return result.status
  elseif self.client:is_running(position.id, { adapter = self.adapter_id }) then
    return "running"
  end
  return "unknown"
end

function SummaryComponent:_state_icon(status)
  if status ~= "running" or not config.summary.animated then
    return icons[status], config.highlights[status]
  end
  return config.icons.running_animated[(self.renders % #config.icons.running_animated) + 1],
    config.highlights.running
end

---@return SummaryComponent
return function(client, adapter_id)
  return SummaryComponent:new(client, adapter_id)
end
