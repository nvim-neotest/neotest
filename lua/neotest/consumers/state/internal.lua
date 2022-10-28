local au_result = "NeoTestStatus"
local au_running = "NeoTestStarted"

---@class state
---@field private _result table<integer, table<string, neotest.Tree> >
---@field private _status table
---@field private _cache table
---@field private _running table<string, table<string, string>>
---@field private _adapters table<integer, string>
---@field private _client neotest.Client
state = {
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
    { pattern = au_running, data = { id = adapter_id, running = position_ids } }
  )
end

---Process results and count pass/fail rates, save to cache
-- Passed, Failed, Skipped
---@param results table<string, neotest.Result>
function state:_process_result(results)
  for path, data in pairs(results) do
    local test_path = string.match(path, "^([^:]*)::")
    if test_path ~= nil then
      local test_name = string.match(path, escape(test_path) .. "::(.*)")
      self:_set_status(test_path, test_name, data.status)
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
  self._running[string.match(adapter_id, "^[^:]*:(.*)")] = nil
  self._result[adapter_id] = results

  self:_process_result(results)

  -- Trigger Event
  vim.api.nvim_exec_autocmds(
    "User",
    { pattern = au_result, data = { id = adapter_id, result = results } }
  )
end

---Alias for client:get_adapters to get registerd adapters
---@return string[]
function state:get_adapters()
  return self._client:get_adapters()
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
function state:running(adapter_id, opts)
  if adapter_id == nil or (type(adapter_id) ~= string and #adapter_id == 0) then
    if opts and not opts.as_array then
      return next(self._running) and self._running or nil
    end

    local array = {}
    local i = 1
    for _, v in pairs(self._running) do
      array[i] = v
      i = i + 1
    end
    return array
  end

  for key, value in pairs(self._running) do
    if
      (
        key == adapter_id
        or (
          opts
          and opts.fuzzy
          and (string.match(adapter_id, escape(key)) or string.match(key, escape(adapter_id)))
        )
      ) and next(value) ~= nil
    then
      return value
    end
  end
  return nil
end

---Get back results from cache
---@param path_query string
---@param opts table
---       :fuzzy use string.match instead of direct comparison for key
---@return table | nil
function state:get_status(path_query, opts)
  for key, val in pairs(self._cache) do
    if key == path_query or (opts and opts.fuzzy and string.match(key, path_query)) then
      return val
    end
  end
  return nil
end

---Get status count (passed | failed | skipped | unknown)
---@param path_query string
---@param opts table
---       :fuzzy use string.match instead of direct comparison for key
---       :status get count for status
---@return integer returns status count, -1 if no status is provided
function state:get_status_count(path_query, opts)
  if not opts and not opts.status then
    return -1
  end
  local status = self:get_status(path_query, opts)
  return status and status[opts.status] or 0
end

---Return entire status cache for all paths
---@return table<string, table>
function state:get_status_all()
  return self._cache
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
end

return state
