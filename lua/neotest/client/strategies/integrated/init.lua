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
  local output_finish_future = nio.control.future()
  local result_code = nil
  local command = spec.command
  local output_accum = FanoutAccum(function(prev, new)
    if not prev then
      return new
    end
    return prev .. new
  end, nil)

  local attach_win, attach_buf, attach_chan, attach_unsubscribe
  local output_path = nio.fn.tempname()
  local open_err, output_fd = nio.uv.fs_open(output_path, "w", 438)
  assert(not open_err, open_err)

  output_accum:subscribe(function(data)
    vim.loop.fs_write(output_fd, data, nil, function(write_err)
      assert(not write_err, write_err)
    end)
  end)

  local success, job = pcall(nio.fn.jobstart, command, {
    cwd = cwd,
    env = env,
    pty = true,
    height = spec.strategy.height,
    width = spec.strategy.width,
    on_stdout = function(_, data)
      if #data == 1 and data[1] == "" then
        output_finish_future.set()
        return
      end
      output_accum:push(table.concat(data, "\n"))
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
      output_accum:subscribe(function(d)
        queue.put_nowait(d)
      end)
      return function()
        local data = nio.first({ queue.get, output_finish_future.wait })
        if data then
          return data
        end
        while queue.size() ~= 0 do
          return queue.get()
        end
      end
    end,
    attach = function()
      -- nvim_create_buf returns 0 on error, but bufexists(0) tests for
      -- existance of an alternate file name, so coerce 0 to nil
      if attach_buf == 0 then
        attach_buf = nil
      end

      if nio.fn.bufexists(attach_buf) == 0 then
        if attach_chan then
          pcall(nio.fn.chanclose, attach_chan)
        end
        if attach_unsubscribe then
          attach_unsubscribe()
        end
        attach_buf = nio.api.nvim_create_buf(false, true)
        attach_chan = lib.ui.open_term(attach_buf, {
          on_input = function(_, _, _, data)
            pcall(nio.api.nvim_chan_send, job, data)
          end,
        })

        attach_unsubscribe = output_accum:subscribe(function(data)
          pcall(nio.api.nvim_chan_send, attach_chan, data)
        end)
      end
      attach_win = lib.ui.float.open({
        height = spec.strategy.height,
        width = spec.strategy.width,
        buffer = attach_buf,
      })
      nio.api.nvim_buf_set_option(attach_buf, "filetype", "neotest-attach")
      nio.api.nvim_buf_set_option(attach_buf, "bufhidden", "wipe")
      attach_win:jump_to()
    end,
    result = function()
      if result_code == nil then
        finish_future.wait()
        if not output_finish_future.is_set() then
          -- jobstart doesn't necessarily call on_stdout if the process
          -- stops quickly, so add a timeout to prevent deadlock
          nio.first({
            output_finish_future.wait,
            function()
              nio.sleep(100)
            end,
          })
        end
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
