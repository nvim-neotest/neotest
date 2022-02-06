local pty = require("neotest.client.strategies.integrated.pty")
local async = require("plenary.async")

local uv = vim.loop

---@class integratedStrategyConfig
---@field height integer
---@field width integer

---@async
---@param spec NeotestRunSpec
---@return NeotestProcess
return function(spec)
  async.util.scheduler()
  local master, slave = pty.openpty(spec.strategy.height, spec.strategy.width)

  local pipe = uv.new_pipe(false)
  pipe:open(master)

  local env, cwd = spec.env, spec.cwd

  local finish_cond = async.control.Condvar.new()
  local result_code = nil
  local command = spec.command

  local process, _ = uv.spawn(command[1], {
    stdio = { slave, slave, slave },
    cwd = cwd,
    env = env,
    detached = false,
    args = #command > 1 and vim.list_slice(command, 2, #command) or nil,
  }, function(code, _)
    result_code = code
    finish_cond:notify_all()
  end)
  local output_path = vim.fn.tempname()
  -- TODO: Resolve permissions issues with opening file with luv
  local output_file = assert(io.open(output_path, "w"))

  local err, unread_data = nil, ""
  local second_reader = nil
  local attach_win, attach_buf, attach_chan

  pipe:read_start(function(err_, data)
    if not err_ then
      unread_data = unread_data .. data
      output_file:write(data)
      if second_reader then
        second_reader(err, unread_data)
        unread_data = ""
      end
    else
      err = err_
    end
  end)

  return {
    is_complete = function()
      return result_code ~= nil
    end,
    output = function()
      return output_path
    end,
    stop = function()
      uv.process_kill(process, 15)
    end,
    attach = function()
      attach_buf = attach_buf or vim.api.nvim_create_buf(false, true)
      attach_chan = attach_chan
        or vim.api.nvim_open_term(attach_buf, {
          on_input = function(_, _, _, data)
            pipe:write(data)
          end,
        })
      attach_win = vim.api.nvim_open_win(attach_buf, true, {
        relative = "cursor",
        row = 1,
        col = 1,
        width = 120,
        height = 20, -- TODO: Get width/height of data
        style = "minimal",
        border = "rounded",
      })
      async.api.nvim_buf_set_keymap(
        attach_buf,
        "n",
        "q",
        "<cmd>lua pcall(vim.api.nvim_win_close, " .. attach_win .. ", true)<CR>",
        { noremap = true, silent = true }
      )
      vim.cmd("autocmd WinLeave * lua pcall(vim.api.nvim_win_close, " .. attach_win .. ", true)")
      second_reader = vim.schedule_wrap(function(err_, data)
        if not err_ then
          vim.api.nvim_chan_send(attach_chan, data)
        end
      end)
      if unread_data ~= "" then
        vim.api.nvim_chan_send(attach_chan, unread_data)
        unread_data = ""
      end
    end,
    result = function()
      finish_cond:wait()
      pipe:close()
      output_file:close()
      if attach_win then
        vim.schedule(function()
          pcall(vim.api.nvim_win_close, attach_win, true)
          pcall(vim.api.nvim_buf_delete, attach_buf, { force = true })
          pcall(vim.fn.chanclose, attach_chan)
        end)
      end
      return result_code
    end,
  }
end
