local async = require("neotest.async")
local FanoutAccum = require("neotest.types").FanoutAccum

---@param spec neotest.RunSpec
---@return neotest.StrategyResult?
return function(spec)
  if vim.tbl_isempty(spec.strategy) then
    return
  end
  local dap = require("dap")

  local handler_id = "neotest_" .. async.fn.localtime()
  local data_accum = FanoutAccum(function(prev, new)
    if not prev then
      return new
    end
    return prev .. new
  end, nil)

  local output_path = vim.fn.tempname()
  local open_err, output_fd = async.uv.fs_open(output_path, "w", 438)
  assert(not open_err, open_err)

  data_accum:subscribe(function(data)
    local write_err, _ = async.uv.fs_write(output_fd, data)
    assert(not write_err, write_err)
  end)

  local finish_cond = async.control.Condvar.new()
  local result_code

  async.util.scheduler()
  dap.run(vim.tbl_extend("keep", spec.strategy, { env = spec.env, cwd = spec.cwd }), {
    before = function(config)
      dap.listeners.after.event_output[handler_id] = function(_, body)
        if vim.tbl_contains({ "stdout", "stderr" }, body.category) then
          async.run(function()
            data_accum:push(body.output)
          end)
        end
      end
      dap.listeners.after.event_exited[handler_id] = function(_, info)
        result_code = info.exitCode
        async.run(function()
          pcall(finish_cond.notify_all, finish_cond)
        end)
      end

      return config
    end,
    after = function()
      dap.listeners.after.event_output[handler_id] = nil
    end,
  })
  return {
    is_complete = function()
      return result_code ~= nil
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
    output = function()
      return output_path
    end,
    attach = function()
      dap.repl.open()
    end,
    result = function()
      finish_cond:wait()
      return result_code
    end,
  }
end
