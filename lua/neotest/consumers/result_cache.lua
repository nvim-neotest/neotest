local nio = require("nio")
local lib = require("neotest.lib")
local Path = require("plenary.path")
local config = require("neotest.config")

---@private
---@type neotest.Client
local client

local neotest = {}

local plugin = "neotest"
local consumer = "result_cache"
local result_cache_file_name = "results.json"

local plugin_cache = Path:new(vim.fn.stdpath("cache")):joinpath(plugin)
local consumer_cache = plugin_cache:joinpath(consumer)

---@toc_entry Result Cache Consumer
---@text
--- A consumer providing a simple interface to cache and fetch test results.
--- The cache is persisted across Neovim sessions.
---@class neotest.consumers.result_cache
neotest.result_cache = {}

---@private
---@async
---@return nil
local function _cache_output_tmp_file(output_file_tmp_path, output_file_cache_path)
  if not lib.files.exists(output_file_cache_path) then
    nio.uv.fs_copyfile(output_file_tmp_path, output_file_cache_path)
  end
end

---@private
---@async
---@param adapter_id string neotest adapter_id
---@return Path adapter_cache_path safe adapter cache path
local function _adapter_cache_path(adapter_id)
  local adapter_cache_name
  if vim.base64 then
    adapter_cache_name = vim.base64.encode(adapter_id)
  else
    adapter_cache_name = adapter_id:gsub("[:/]", "")
  end
  return consumer_cache:joinpath(adapter_cache_name)
end
--- Cache test results to cache file
---@async
---@return nil
function neotest.result_cache:cache()
  plugin_cache:mkdir()
  consumer_cache:mkdir()

  local results_to_cache = {}
  for _, adapter_id in pairs(client:get_adapters()) do
    local adapter_cache_path = _adapter_cache_path(adapter_id)
    adapter_cache_path:mkdir()
    local adapter_results = client:get_results(adapter_id)
    for key, result in pairs(adapter_results) do
      if result.output then
        local result_output = Path:new(result.output)
        local result_filename =
          vim.split(tostring(result_output), tostring(result_output:parent()))[2]
        local output_file_cache_path = adapter_cache_path:joinpath(result_filename:sub(2))
        _cache_output_tmp_file(result.output, tostring(output_file_cache_path))
        adapter_results[key].output = tostring(output_file_cache_path)
      end
    end
    results_to_cache[adapter_id] = adapter_results

    local result_cache_file_path = adapter_cache_path:joinpath(result_cache_file_name)
    lib.files.write(tostring(result_cache_file_path), vim.json.encode(results_to_cache))
    vim.notify("Test results cached.")
  end
end

neotest.result_cache.cache = nio.create(neotest.result_cache.cache, 1)

--- Clear cached test results
---@async
---@return nil
function neotest.result_cache:clear()
  local cache_files = lib.files.find(tostring(consumer_cache))
  for _, file in pairs(cache_files) do
    os.remove(file)
  end
end

neotest.result_cache.clear = nio.create(neotest.result_cache.clear, 1)

--- Loads previously cached test results
---@async
---@return nil
function neotest.result_cache:fetch()
  for _, adapter_id in pairs(client:get_adapters()) do
    local result_cache_file_path = _adapter_cache_path(adapter_id):joinpath(result_cache_file_name)

    if result_cache_file_path:exists() then
      local cached_results = vim.json.decode(lib.files.read(tostring(result_cache_file_path)))
      client:load_results(cached_results)
    end
  end
end

neotest.result_cache.fetch = nio.create(neotest.result_cache.fetch, 1)

neotest.result_cache = setmetatable(neotest.result_cache, {
  ---@param client_ neotest.Client
  __call = function(_, client_)
    client = client_

    if config.state.fetch_results_on_startup then
      client.listeners.started = function()
        neotest.result_cache:fetch()
      end
    end
    return neotest.result_cache
  end,
})

return neotest.result_cache
