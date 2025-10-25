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
  local output_finish_future = nio.control.future()
  local pending_output_tasks = 0
  local finish_requested = false

  local function maybe_finish_output()
    if finish_requested and pending_output_tasks == 0 and not output_finish_future.is_set() then
      output_finish_future.set()
    end
  end

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
          pending_output_tasks = pending_output_tasks + 1
          nio.run(function()
            local ok, err = pcall(data_accum.push, data_accum, body.output)
            pending_output_tasks = pending_output_tasks - 1
            maybe_finish_output()
            if not ok then
              error(err)
            end
          end)
        end
      end
      dap.listeners.after.event_exited[handler_id] = function(_, info)
        result_code = info.exitCode
        finish_requested = true
        maybe_finish_output()
        pcall(finish_future.set)
      end

      return adapter_before and adapter_before() or config
    end,
    after = function()
      if result_code == nil then
        result_code = 0
      end
      finish_requested = true
      maybe_finish_output()
      pcall(finish_future.set)
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
      data_accum:subscribe(function(data)
        -- Keep writer coroutine non-blocking so pending task counter drains immediately
        queue.put_nowait(data)
      end)
      return function()
        -- Race next chunk vs. output flush completion; `data == nil` means flush future fired
        local data = nio.first({ queue.get, output_finish_future.wait })
        if data then
          -- Happy path: queue produced a chunk before we learned output is done
          return data
        end
        -- Flush any late-arriving chunks that landed after the finish future resolved
        while queue.size() ~= 0 do
          return queue.get()
        end
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
      if not output_finish_future.is_set() then
        -- Allow output-side timeout so fast exits still flush through the accumulator
        nio.first({
          output_finish_future.wait,
          function()
            nio.sleep(100)
          end,
        })
      end
      return result_code
    end,
  }
end
