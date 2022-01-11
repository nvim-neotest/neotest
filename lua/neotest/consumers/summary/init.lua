---@param client NeotestClient
local consumer_name = "neotest-summary"
local config = require("neotest.config")
---@param client NeotestClient
return function(client)
  local RenderState = require("neotest.consumers.summary.render")
  local SummaryComponent = require("neotest.consumers.summary.component")
  local async = require("plenary.async")

  local buf_name = "Neotest Summary"
  local summary_buf

  local function create_buf()
    if summary_buf then
      return summary_buf
    end

    summary_buf = async.api.nvim_create_buf(false, true)
    local options = {
      modifiable = false,
      filetype = "neotest-summary",
    }
    for name, value in pairs(options) do
      async.api.nvim_buf_set_option(summary_buf, name, value)
    end
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
    local options = {
      relativenumber = false,
      number = false,
      winfixwidth = true,
    }
    for name, value in pairs(options) do
      async.api.nvim_win_set_option(win, name, value)
    end
    async.api.nvim_win_set_buf(win, buf)
    async.api.nvim_set_current_win(cur_win)
  end

  local component = SummaryComponent(client)

  local render = function(expanded)
    if not is_open() then
      return
    end
    local tree = client:get_position()
    if not tree then
      return
    end
    local render_state = RenderState.new(config.summary)
    component:render(render_state, tree, expanded or {})
    render_state:render_buffer(summary_buf)
  end

  local listener = function()
    render()
  end
  client.listeners.discover_positions[consumer_name] = listener
  client.listeners.run[consumer_name] = listener
  client.listeners.results[consumer_name] = function(results)
    if not config.summary.expand_errors then
      render()
    end
    local expanded = {}
    for pos_id, result in pairs(results) do
      if
        result.status == "failed"
        and client:get_position(pos_id, false)
        and #client:get_position(pos_id):children() > 0 -- TODO: Not use hidden prop
      then
        expanded[pos_id] = true
      end
    end
    render(expanded)
  end

  local started = false
  local start = function()
    started = true
    if config.summary.follow then
      vim.cmd([[ 
    augroup NeotestSummaryFollow
      au!
      au BufEnter,BufWrite * lua require("neotest").summary.expand(vim.fn.expand("<afile>:p"), true)
    augroup END
    ]])
    end
  end

  local function open()
    if not started then
      start()
    end
    create_buf()
    open_window(summary_buf)
  end

  return {
    render = render,
    toggle = function()
      async.run(function()
        if is_open() then
          local win = async.fn.win_getid(async.fn.bufwinnr(summary_buf))
          async.api.nvim_win_close(win, true)
        else
          open()
          render()
        end
      end)
    end,
    expand = function(pos_id, recursive)
      async.run(function()
        local tree = client:get_position(pos_id, false)
        if not tree then
          return
        end
        local expanded = {}
        if recursive then
          for _, pos in tree:iter() do
            expanded[pos.id] = true
          end
        else
          expanded[pos_id] = true
        end
        for parent in tree:iter_parents() do
          expanded[parent:data().id] = true
        end
        render(expanded)
      end)
    end,
  }
end
