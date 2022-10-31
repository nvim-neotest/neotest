-- The state consumer acts as a cache for the internal test state as provided by
-- by the neotest core. It can be used to query get the current number of
-- passed/failed/skipped tests in a simple manner, to display in e.g. a statusbar.

local internal_state = require("neotest.consumers.state.internal")

local neotest = {}
neotest.state = {}

---Get the list of all known adapter IDs
---@return string[]
function neotest.state.get_adapters()
  return internal_state:get_adapters()
end

---Get back results from cache. Fetches all results by default.
---@param opts table
---@field path_query string optionally get result back for specific file or path
---@field fuzzy string use string.match instead of direct comparison for key
---@return table | nil
function neotest.state.get_status(opts)
  return internal_state:get_status(opts)
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

---Gives back unparsed results
---Get back results from cache
function neotest.state.get_raw_results()
  return internal_state:get_raw_results()
end

---Check if there are tests running
---If no options are provided, all running processes will be returned.
---If nil is returned your adapter_id found no match, otherwise an empty
---table is returned.
---@param opts table
---@field adapter_id string Optionally, provide a "<adapter_id>:<file_path>" argument to filter on.
---@field fuzzy string use string.match instead of direct comparison for key
---@return table<string, string> | string[] | nil
function neotest.state.running(opts)
  return internal_state:running(opts)
end

neotest.state = setmetatable(neotest.state, {
  __call = function(_, _client)
    internal_state:init(_client)
    return neotest.state
  end,
})

return neotest.state
