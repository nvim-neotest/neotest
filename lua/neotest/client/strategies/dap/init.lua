local nio = require("nio")
local lib = require("neotest.lib")
local FanoutAccum = require("neotest.types").FanoutAccum

---@param adapter neotest.Adapter
---@param position neotest.Position
---@return string|nil
local function get_test_filetype(adapter, position)
  local path_matcher = position.path and string.format("^%s$", position.path)
  local test_bufnr = nio.fn.bufnr(path_matcher or -1)
  if test_bufnr ~= -1 then
    return nio.api.nvim_buf_get_option(test_bufnr, "filetype")
  end

  for _, buf in ipairs(nio.api.nvim_list_bufs()) do
    local name = nio.api.nvim_buf_get_name(buf)
    local real = lib.files.path.real(name)
    if real and adapter.is_test_file(real) then
      return nio.api.nvim_buf_get_option(buf, "filetype")
    end
  end
end

---@param spec neotest.RunSpec
---@param context neotest.StrategyContext
---@return neotest.StrategyResult?
return function(spec, context)
  if vim.tbl_isempty(spec.strategy) then
    return
  end
  local dap = require("dap")

  local handler_id = "neotest_" .. nio.fn.localtime()
  local data_accum = FanoutAccum(function(prev, new)
    if not prev then
      return new
    end
    return prev .. new
  end, nil)

  local output_path = vim.fn.tempname()
  local open_err, output_fd = nio.uv.fs_open(output_path, "w", 438)
  assert(not open_err, open_err)

  data_accum:subscribe(function(data)
    local write_err, _ = nio.uv.fs_write(output_fd, data)
    assert(not write_err, write_err)
  end)

  local finish_future = nio.control.future()
  local result_code

  local adapter_before = spec.strategy.before
  local adapter_after = spec.strategy.after
  spec.strategy.before = nil
  spec.strategy.after = nil

  nio.scheduler()
  dap.run(vim.tbl_extend("keep", spec.strategy, { env = spec.env, cwd = spec.cwd }), {
    filetype = get_test_filetype(context.adapter, context.position),
    before = function(config)
      dap.listeners.after.event_output[handler_id] = function(_, body)
        if vim.tbl_contains({ "stdout", "stderr" }, body.category) then
          nio.run(function()
            data_accum:push(body.output)
          end)
        end
      end
      dap.listeners.after.event_exited[handler_id] = function(_, info)
        result_code = info.exitCode
        pcall(finish_future.set)
      end

      return adapter_before and adapter_before() or config
    end,
    after = function()
      local received_exit = result_code ~= nil
      if not received_exit then
        result_code = 0
        pcall(finish_future.set)
      end
      dap.listeners.after.event_output[handler_id] = nil
      dap.listeners.after.event_exited[handler_id] = nil
      if adapter_after then
        adapter_after()
      end
    end,
  })
  return {
    is_complete = function()
      return result_code ~= nil
    end,
    output_stream = function()
      local queue = nio.control.queue()
      data_accum:subscribe(queue.put)
      return function()
        return nio.first({ finish_future.wait, queue.get })
      end
    end,
    output = function()
      return output_path
    end,
    attach = function()
      dap.repl.open()
    end,
    stop = function()
      dap.terminate()
    end,
    result = function()
      finish_future:wait()
      return result_code
    end,
  }
end
