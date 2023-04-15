local nio = require("nio")
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

  local finish_future = nio.control.future()
  local result_code = nil
  local command = spec.command
  local data_accum = FanoutAccum(function(prev, new)
    if not prev then
      return new
    end
    return prev .. new
  end, nil)

  local attach_win, attach_buf, attach_chan
  local output_path = nio.fn.tempname()
  local open_err, output_fd = nio.uv.fs_open(output_path, "w", 438)
  assert(not open_err, open_err)

  data_accum:subscribe(function(data)
    local write_err, _ = nio.uv.fs_write(output_fd, data)
    assert(not write_err, write_err)
  end)

  local success, job = pcall(nio.fn.jobstart, command, {
    cwd = cwd,
    env = env,
    pty = true,
    height = spec.strategy.height,
    width = spec.strategy.width,
    on_stdout = function(_, data)
      nio.run(function()
        data_accum:push(table.concat(data, "\n"))
      end)
    end,
    on_exit = function(_, code)
      result_code = code
      finish_future.set()
    end,
  })
  if not success then
    local write_err, _ = nio.uv.fs_write(output_fd, job)
    assert(not write_err, write_err)
    result_code = 1
    finish_future.set()
  end
  return {
    is_complete = function()
      return result_code ~= nil
    end,
    output = function()
      return output_path
    end,
    stop = function()
      nio.fn.jobstop(job)
    end,
    output_stream = function()
      local queue = nio.control.queue()
      data_accum:subscribe(function(d)
        queue.put(d)
      end)
      return function()
        return nio.first({ finish_future.wait, queue.get })
      end
    end,
    attach = function()
      if not attach_buf then
        attach_buf = nio.api.nvim_create_buf(false, true)
        attach_chan = lib.ui.open_term(attach_buf, {
          on_input = function(_, _, _, data)
            pcall(nio.api.nvim_chan_send, job, data)
          end,
        })
        data_accum:subscribe(function(data)
          nio.api.nvim_chan_send(attach_chan, data)
        end)
      end
      attach_win = lib.ui.float.open({
        height = spec.strategy.height,
        width = spec.strategy.width,
        buffer = attach_buf,
      })
      vim.api.nvim_buf_set_option(attach_buf, "filetype", "neotest-attach")
      attach_win:jump_to()
    end,
    result = function()
      if result_code == nil then
        finish_future:wait()
      end
      local close_err = nio.uv.fs_close(output_fd)
      assert(not close_err, close_err)
      pcall(nio.fn.chanclose, job)
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
