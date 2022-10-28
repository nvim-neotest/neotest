-- The state consumer acts as a cache for the internal test state as provided by
-- by the neovim client. It can be used to query get the current number of
-- passed/failed/skipped tests in a simple manner, to display in e.g. a statusbar.

local internal_state = require("neotest.consumers.state.internal")

local neotest = {}
neotest.state = {}

---Alias for client:get_adapters to get registerd adapters
---@return string[]
function neotest.state.get_adapters()
  return internal_state:get_adapters()
end

---Get back results from cache
---@param path_query string
---@param opts table
---       :fuzzy use string.match instead of direct comparison for key
---@return table | nil
function neotest.state.get_status(path_query, opts)
  return internal_state:get_status(path_query, opts)
end

---Get status count (passed | failed | skipped | unknown)
---@param path_query string
---@param opts table
---       :fuzzy use string.match instead of direct comparison for key
---       :status get count for status
---@return integer returns status count, -1 if no status is provided
function neotest.state.get_status_count(path_query, opts)
  return internal_state:get_status_count(path_query, opts)
end

---Return entire status cache from the last run.
---ONLY returns the results from the last run per file, not the enire test history.
---@return table<string, table>
function neotest.state.get_status_all()
  return internal_state:get_status_all()
end

---Gives back unparsed results
---Get back results from cache
function neotest.state.get_raw_results()
  return internal_state:get_raw_results()
end

---Check if there are tests running
---Optionally, provide a "<adapter_id>:<file_path>" argument to filter on.
---If no argument is provided, all running processes will be returned.
---If nil is returned your adapter_id found no match, otherwise an emtpy
---table is returned.
---@param adapter_id string optional
---@param opts table
---       :fuzzy use string.match instead of direct comparison for key
---       :as_array if no addapter_id provided, return entire list as array
---@return table<string, string> | string[] | nil
function neotest.state.running(adapter_id, opts)
  return internal_state:running(adapter_id, opts)
end

neotest.state = setmetatable(neotest.state, {
  __call = function(_, _client)
    internal_state:init(_client)
    return neotest.state
  end,
})

return neotest.state
