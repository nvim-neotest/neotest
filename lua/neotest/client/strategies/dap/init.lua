local async = require("plenary.async")

---@param spec NeotestRunSpec
---@return NeotestStrategyResult
return function(spec)
  local dap = require("dap")

  local handler_id = "neotest_" .. async.fn.localtime()

  local output_path = vim.fn.tempname()
  local output_file = assert(io.open(output_path, "w"))

  local finish_cond = async.control.Condvar.new()
  local result_code

  dap.run(spec.strategy, {
    before = function(config)
      dap.listeners.after.event_output[handler_id] = function(_, body)
        if vim.tbl_contains({ "stdout", "stderr" }, body.category) then
          output_file:write(body.output)
        end
      end
      dap.listeners.after.event_exited[handler_id] = function(_, info)
        result_code = info.exitCode
        finish_cond:notify_all()
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
