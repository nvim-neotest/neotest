local au_result = "NeotestResult"
local au_started = "NeotestStarted"

---@class neotest.StateConsumer
---@field private _result table<integer, table<string, neotest.Tree> >
---@field private _status table
---@field private _cache table
---@field private _running table<string, table<string, string>>
---@field private _adapters table<integer, string>
---@field private _client neotest.Client
local state = {
  _result = {},
  _status = {},
  _cache = {},
  _running = {},
  _adapters = {},
}

---Escape characters that have a special meaning in patterns
---@param text string
---@return string
local function escape(text)
  text = text:gsub("%-", "%%-")
  text = text:gsub("%.", "%%.")
  return text
end

---Perform a double fuzzy match on two strings
---@param a string
---@param b string
---@return boolean
local function fuzzy_match(a, b)
  return string.match(a, escape(b)) or string.match(b, escape(a))
end

---Update the internal list of currently running tests
---@param adapter_id string
---@param position_ids string
function state:_update_running(adapter_id, position_ids)
  self._running[position_ids] = {
    adapter = string.match(adapter_id, "(.-):"),
    path = position_ids,
  }
  -- Trigger Event
  vim.api.nvim_exec_autocmds(
    "User",
    { pattern = au_started, data = { adapter_id = adapter_id, running = position_ids } }
  )
end

---Process results and count pass/fail rates, save to cache
---Passed, Failed, Skipped
---@param tree neotest.Tree|nil
function state:_process_result(tree, results)
  if not tree then
    return
  end
  for _, pos in tree:iter() do
    if pos.type == "test" then
      if results[pos.id].status then
        self:_set_status(pos.path, pos.name, results[pos.id].status)
      end
    end
  end
  self:_update_cache()
end

---Update status for specific test
---@param path string
---@param status string
function state:_set_status(path, name, status)
  if self._status[path] == nil then
    self._status[path] = {}
  end
  self._status[path][name] = status
end

---Update the cache status count
function state:_update_cache()
  for path, results in pairs(self._status) do
    local count = { passed = 0, failed = 0, skipped = 0, unknown = 0 }
    for _, status in pairs(results) do
      count[status] = count[status] + 1
    end
    self._cache[path] = count
  end
end

---Receive result from event and add to internal state
---@param adapter_id string
---@param results table<string, neotest.Result>
function state:_update_results(adapter_id, results)
  local position_id = string.match(adapter_id, "^[^:]*:(.*)")

  self._running[position_id] = nil
  self._result[adapter_id] = results

  local tree, _ = self._client:get_position(position_id, { adapter = adapter_id })

  self:_process_result(tree, results)

  -- Trigger Event
  vim.api.nvim_exec_autocmds(
    "User",
    { pattern = au_result, data = { id = adapter_id, result = results } }
  )
end

---Get the list of all known adapter IDs
---@return string[]
function state:get_adapters()
  if not self._client:has_started() then
    return {}
  end
  return self._client:get_adapters()
end

---Check if there are tests running
---If no options are provided, all running processes will be returned.
---If nil is returned your adapter_id found no match, otherwise an empty
---table is returned.
---@param opts table
---@field adapter_id string Optionally, provide a "<adapter_id>:<file_path>" argument to filter on.
---@field fuzzy string use string.match instead of direct comparison for key
---@return table<string, string> | string[] | nil
function state:running(opts)
  opts = opts or {}
  if not opts.adapter_id or (type(opts.adapter_id) ~= string and #opts.adapter_id == 0) then
    return next(self._running) and self._running or nil
  end
  for key, value in pairs(self._running) do
    if
      (key == opts.adapter_id or (opts.fuzzy and fuzzy_match(opts.adapter_id, key)))
      and next(value) ~= nil
    then
      return value
    end
  end
  return nil
end

---Get back results from cache. Fetches all results by default.
---@param opts table
---@field status string fetch count for specific status (passed | failed | skipped | unknown)
---@field query string optionally get result back for specific file or path
---@field fuzzy string use string.match instead of direct comparison for key
---@return table | nil
function state:get_status(opts)
  opts = opts or {}
  local status = self:_get_status(opts)
  if opts.status then
    return status and status[opts.status]
  end
  return status
end

---Get back results from cache
---@param opts table
---@field query string optionally get result back for specific file or path
---@field fuzzy string use string.match instead of direct comparison for key
---@return table | nil
function state:_get_status(opts)
  opts = opts or {}
  if not opts.query then
    return self._cache
  end
  for key, val in pairs(self._cache) do
    if key == opts.query or (opts.fuzzy and fuzzy_match(key, opts.query)) then
      return val
    end
  end
  return nil
end

---Gives back unparsed results
---Get back results from cache
function state:get_raw_results()
  return self._result
end

---@param client neotest.Client
function state:init(client)
  self._client = client

  -- Register event listerer to receive state
  -- This gets run twice for one event ??
  client.listeners.results = function(adapter_id, results)
    self:_update_results(adapter_id, results)
  end

  client.listeners.run = function(adapter_id, position_ids)
    self:_update_running(adapter_id, position_ids)
  end

  --TODO: Listen for client.listeners.discover_positions to also track untested tests
end

return state
