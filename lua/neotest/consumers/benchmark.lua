local nio = require("nio")
local lib = require("neotest.lib")
local profile_available, profile = pcall(require, "plenary.profile")

---@private
---@type neotest.Client
local client

local neotest = {}

---@toc_entry Benchmark Consumer
---@text
--- A consumer providing methods for benchmarking neotest.
--- This is not intended for end user usage.
neotest.benchmark = {}

--- This is not intended for end user usage but just for testing the impact of changes on performance.
--- The interface for this is completely open to change without counting as a breaking change.
function neotest.benchmark.start(args)
  if not profile_available then
    error(("Benchmark not available: %s"):format(profile))
  end
  args = args or {}
  local log_path = args.log_path or "profile.log"
  local svg_path = args.svg_path or "profile.svg"
  local count = args.num_runs or 10

  nio.run(function()
    local total_time = 0
    profile.start(log_path, { flame = true })
    for _ = 1, count, 1 do
      io.stdout:write("Starting client\n")
      local time = client:_start({ autocmds = false, force = true })
      total_time = total_time + time
      io.stdout:write("Startup Complete\nTime: " .. time .. "(s)\n")
    end
    profile.stop()
    io.stdout:write(("Number of runs: %s\n"):format(count))
    io.stdout:write(("Total time: %s\n"):format(total_time))
    io.stdout:write(("Average time: %s\n"):format(total_time / count))
    io.stdout:write(("Wrote log to '%s'\n"):format(log_path))
    local flamegraph_exec
    if nio.fn.executable("inferno-flamegraph") == 1 then
      flamegraph_exec = "inferno-flamegraph"
    elseif nio.fn.executable("flamegraph") == 1 then
      flamegraph_exec = "flamegraph"
    end
    if flamegraph_exec then
      io.stdout:write(("Writing flamegraph to '%s'\n"):format(svg_path))
      local _, output = lib.process.run({ flamegraph_exec, log_path }, { stdout = true })
      lib.files.write(svg_path, output.stdout)
    else
      io.stdout:write("Unable to find flamegraph executable\n")
    end
    nio.scheduler()
    vim.cmd("quit")
  end)
end

neotest.benchmark = setmetatable(neotest.benchmark, {
  __call = function(_, client_)
    client = client_
    return neotest.benchmark
  end,
})

return neotest.benchmark
