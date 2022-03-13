---@class neotest.Adapter
---@field name string
local NeotestAdapter = {}

---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function NeotestAdapter.root(dir) end

---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path) end

---@async
---@param file_path string
---@return neotest.Tree | nil
function NeotestAdapter.discover_positions(file_path) end

---@param args neotest.RunArgs
---@return neotest.RunSpec
function NeotestAdapter.build_spec(args) end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestAdapter.results(spec, result, tree) end
