local async = require("neotest.async")
local lib = require("neotest.lib")
local config = require("neotest.config")

local win, short_opened

local function open_output(result, opts)
  local output = opts.short and result.short or (result.output and lib.files.read(result.output))
  if not output then
    if not opts.quiet then
      lib.notify("Output not found for position", "warn")
    end
    return
  end
  local buf = async.api.nvim_create_buf(false, true)
  local chan = async.api.nvim_open_term(buf, {})
  short_opened = opts.short
  -- See https://github.com/neovim/neovim/issues/14557
  local dos_newlines = string.find(output, "\r\n") ~= nil
  async.api.nvim_chan_send(chan, dos_newlines and output or output:gsub("\n", "\r\n"))
  async.util.sleep(10) -- Wait for chan to send
  async.api.nvim_create_autocmd("TermEnter", {
    buffer = buf,
    callback = function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true),
        "n",
        false
      )
    end,
  })

  local lines = async.api.nvim_buf_get_lines(buf, 0, -1, false)
  local width, height = 80, #lines
  for i, line in ipairs(lines) do
    if i > 500 then
      break -- Don't want to parse very long output
    end
    local line_length = vim.str_utfindex(line)
    if line_length > width then
      width = line_length
    end
  end

  local on_close = function()
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    pcall(vim.fn.chanclose, chan)
    win = nil
  end
  if opts.open_win then
    local cur_win = vim.api.nvim_get_current_win()
    win = opts.open_win({ width = width, height = height })
    if not win then
      win = vim.api.nvim_get_current_win()
    end
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      callback = on_close,
    })
    vim.api.nvim_win_set_buf(win, buf)
    if opts.enter then
      vim.api.nvim_set_current_win(win)
    else
      vim.api.nvim_set_current_win(cur_win)
    end
  else
    local float = lib.ui.float.open({
      width = width,
      height = height,
      buffer = buf,
      enter = opts.enter,
    })
    float:listen("close", on_close)
    win = float.win_id
  end

  async.api.nvim_buf_set_keymap(buf, "n", "q", "", {
    noremap = true,
    silent = true,
    callback = function()
      pcall(vim.api.nvim_win_close, win, true)
    end,
  })
end

---@tag neotest.output

---@brief [[
--- A consumer that displays the output of test results.
---@brief ]]
local neotest = {}
neotest.output = {}

---@type neotest.Client
local client

local init = function()
  if config.output.open_on_run then
    client.listeners.results = function(_, results)
      if win then
        return
      end
      local cur_pos = async.fn.getpos(".")
      local line = cur_pos[2] - 1
      local buf_path = vim.fn.expand("%:p")
      local positions = client:get_position(buf_path)
      if not positions then
        return
      end
      for _, pos in positions:iter() do
        if
          pos.type == "test"
          and results[pos.id]
          and results[pos.id].status == "failed"
          and pos.range[1] <= line
          and pos.range[3] >= line
        then
          open_output(
            results[pos.id],
            { short = config.output.open_on_run == "short", enter = false, quiet = true }
          )
        end
      end
    end
  end
end

---Open the output of a test result
---<pre>
--->
---lua require("neotest").output.open({ enter = true })
---</pre>
---@param opts table
---@field open_win function: Function that takes a table with width and height keys and opens a window for the output. If a window ID is not returned, the current window will be used
---@field short boolean: Show shortened output
---@field enter boolean: Enter output window
---@field quiet boolean: Suppress warnings of no output
---@field position_id string: Open output for position with this ID, opens nearest position if not given
---@field adapter string: Adapter ID, defaults to first found with matching position
function neotest.output.open(opts)
  opts = opts or {}
  if win then
    if opts.short ~= short_opened then
      pcall(vim.api.nvim_win_close, win, true)
    else
      if pcall(vim.api.nvim_set_current_win, win) then
        return
      end
      opts.enter = true
    end
  end
  async.run(function()
    local tree, adapter_id
    if not opts.position_id then
      local file_path = vim.fn.expand("%:p")
      local row = vim.fn.getbufinfo(file_path)[1].lnum - 1
      tree, adapter_id = client:get_nearest(file_path, row, opts)
    else
      tree, adapter_id = client:get_position(opts.position_id, opts)
    end
    if not tree then
      lib.notify("No tests found in file", "warn")
      return
    end
    local result = client:get_results(adapter_id)[tree:data().id]
    if not result then
      lib.notify("No output for " .. tree:data().name)
      return
    end
    open_output(result, opts)
  end)
end

neotest.output = setmetatable(neotest.output, {
  __call = function(_, client_)
    client = client_
    init()
    return neotest.output
  end,
})

return neotest.output
