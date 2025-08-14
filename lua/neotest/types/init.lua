local M = {}

---@enum neotest.PositionType
M.PositionType = {
  dir = "dir",
  file = "file",
  namespace = "namespace",
  test = "test",
}

---@class neotest.Position
---@field id string
---@field type neotest.PositionType
---@field name string
---@field path string
---@field range integer[]

---@enum neotest.ResultStatus
M.ResultStatus = {
  passed = "passed",
  failed = "failed",
  skipped = "skipped",
}

---@class neotest.Result
---@field status neotest.ResultStatus
---@field output? string Path to file containing full output data
---@field short? string Shortened output string
---@field errors? neotest.Error[]

---@class neotest.Error
---@field message string
---@field line? integer
---@field severity? integer Diagnostic severity (see vim.diagnostic.severity)

---@class neotest.Process
---@field output async fun(): string Path to file containing output data
---@field is_complete fun() boolean Is process complete
---@field result async fun() integer Get result code of process (async)
---@field attach async fun() Attach to the running process for user input
---@field stop async fun() Stop the running process
---@field output_stream async fun(): async fun(): string Async iterator of process output

---@class neotest.StrategyContext
---@field position neotest.Position
---@field adapter neotest.Adapter

---@alias neotest.Strategy async fun(spec: neotest.RunSpec, context: neotest.StrategyContext): neotest.Process

---@class neotest.StrategyResult
---@field code integer
---@field output string

---@class neotest.RunArgs
---@field tree neotest.Tree
---@field extra_args? string[]
---@field strategy string

---@class neotest.RunSpec
---@field command string[]
---@field env? table<string, string>
---@field cwd? string
---@field context? table Arbitrary data to preserve state between running and result collection
---@field strategy? table|neotest.Strategy Arguments for strategy or override for chosen strategy
---@field stream? fun(output_stream: fun(): string[]): fun(): table<string, neotest.Result>

M.Tree = require("neotest.types.tree")
M.FanoutAccum = require("neotest.types.fanout_accum")

return M
