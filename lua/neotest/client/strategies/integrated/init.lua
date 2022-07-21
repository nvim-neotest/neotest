local async = require("neotest.async")
local lib = require("neotest.lib")
local FanoutAccum = require("neotest.types").FanoutAccum

---@class integratedStrategyConfig
---@field height integer
---@field width integer

---@async
---@param spec neotest.RunSpec
---@return neotest.Process
return function(spec)
  local env, cwd = spec.env, spec.cwd

  local finish_cond = async.control.Condvar.new()
  local result_code = nil
  local command = spec.command
  local data_accum = FanoutAccum(function(prev, new)
    if not prev then
      return new
    end
    return prev .. new
  end, nil)

  local attach_win, attach_buf, attach_chan
  local output_path = async.fn.tempname()
  local open_err, output_fd = async.uv.fs_open(output_path, "w", 438)
  assert(not open_err, open_err)

  data_accum:subscribe(function(data)
    local write_err, _ = async.uv.fs_write(output_fd, data)
    assert(not write_err, write_err)
  end)

  local success, job = pcall(async.fn.jobstart, command, {
    cwd = cwd,
    env = env,
    pty = true,
    height = spec.strategy.height,
    width = spec.strategy.width,
    on_stdout = function(_, data)
      async.run(function()
        data_accum:push(table.concat(data, "\n"))
      end)
    end,
    on_exit = function(_, code)
      result_code = code
      finish_cond:notify_all()
    end,
  })
  if not success then
    local write_err, _ = async.uv.fs_write(output_fd, job)
    assert(not write_err, write_err)
    result_code = 1
    finish_cond:notify_all()
  end
  return {
    is_complete = function()
      return result_code ~= nil
    end,
    output = function()
      return output_path
    end,
    stop = function()
      async.fn.jobstop(job)
    end,
    output_stream = function()
      local sender, receiver = async.control.channel.mpsc()
      data_accum:subscribe(function(d)
        sender.send(d)
      end)
      return function()
        return async.lib.first(function()
          finish_cond:wait()
        end, receiver.recv)
      end
    end,
    attach = function()
      if not attach_buf then
        attach_buf = vim.api.nvim_create_buf(false, true)
        attach_chan = vim.api.nvim_open_term(attach_buf, {
          on_input = function(_, _, _, data)
            pcall(async.api.nvim_chan_send, job, data)
          end,
        })
        data_accum:subscribe(function(data)
          async.api.nvim_chan_send(attach_chan, data)
        end)
      end
      attach_win = lib.ui.float.open({
        height = spec.strategy.height,
        width = spec.strategy.width,
        buffer = attach_buf,
      })
      async.api.nvim_buf_set_keymap(attach_buf, "n", "q", "", {
        noremap = true,
        silent = true,
        callback = function()
          pcall(vim.api.nvim_win_close, attach_win.win_id, true)
        end,
      })
      attach_win:jump_to()
    end,
    result = function()
      if result_code == nil then
        finish_cond:wait()
      end
      local close_err = async.uv.fs_close(output_fd)
      assert(not close_err, close_err)
      pcall(async.fn.chanclose, job)
      if attach_win then
        attach_win:listen("close", function()
          pcall(vim.api.nvim_buf_delete, attach_buf, { force = true })
          pcall(vim.fn.chanclose, attach_chan)
        end)
      end
      return result_code
    end,
  }
end
