---@class NeotestAdapter
---@field name string
local NeotestAdapter = {}


---@async
---@param file_path string
---@return boolean
function NeotestAdapter.is_test_file(file_path) end

---@async
---@param path string
---@return Tree | nil
function NeotestAdapter.discover_positions(path) end

---@param args NeotestRunArgs
---@return NeotestRunSpec
function NeotestAdapter.build_spec(args) end

---@async
---@param spec NeotestRunSpec
---@param result NeotestStrategyResult
---@return table<string, NeotestResult>
function NeotestAdapter.results(spec, result) end
