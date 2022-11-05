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

---Get back status results from cache. Fetches all results by default.
---Can be used to fetch the count for a specific status.
---@param opts table
---@field status string optionally fetch count for specific status (passed | failed | skipped | unknown)
---@field query string optionally get result back for specific file or path
---@field fuzzy string use string.match instead of direct comparison for key
---@field total boolean return total results. If used in combination with a query
---       the query result will take precent if present, otherwise total will be used as fallback.
---       This is useful when you want to return package wide results on non-code windows
---@return table | nil
function neotest.state.get_status(opts)
  return internal_state:get_status(opts)
end

---Gives back unparsed results
---Get back results from cache
function neotest.state.get_raw_results()
  return internal_state:get_raw_results()
end

---Check if there are tests currently running
---If no options are provided, all running processes will be returned.
---If either no tests are running, or the query found no match, nil is returned
---@param opts table
---@field query string Optionally, provide a query to filter on.
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
