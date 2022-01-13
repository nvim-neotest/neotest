---@class NeotestPosition
---@field id string
---@field type "dir" | "file" | "namespace" | "test"
---@field name string
---@field path string
---@field range integer[]

---@class NeotestResult
---@field status "passed" | "failed" | "skipped"
---@field output? string Path to file containing full output data
---@field short? string Shortened output string
---@field errors? NeotestError[]

---@class NeotestError
---@field message string
---@field line? integer

---@class NeotestProcess
---@field output async fun():string Output data
---@field is_complete fun(): boolean Is process complete
---@field result async fun(): integer Get result code of process (async)
---@field attach async fun() Attach to the running process for user input
---@field stop async fun() Stop the running process

---@alias NeotestStrategy async fun(spec: NeotestRunSpec): NeotestProcess

---@class NeotestStrategyResult
---@field code integer
---@field output string

---@class NeotestRunArgs
---@field tree? Tree
---@field extra_args? string[]
---@field strategy string

---@class NeotestRunSpec
---@field command string[]
---@field env? table<string, string>
---@field cwd? string
---@field context? table Arbitrary data to preserve state between running and result collection
---@field strategy? table Arguments for strategy

local M = {}

M.Tree = require("neotest.types.tree")
M.FIFOQueue = require("neotest.types.queue")

return M
