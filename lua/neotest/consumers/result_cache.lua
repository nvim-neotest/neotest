local nio = require("nio")
local lib = require("neotest.lib")

---@private
---@type neotest.Client
local client

local neotest = {}

local plugin = "neotest"
local consumer = "result_cache"
local result_cache_file_name = "results.json"

local plugin_cache = vim.fn.stdpath("cache") .. "/" .. plugin
local consumer_cache = plugin_cache .. "/" .. consumer
local result_cache_file_path = consumer_cache .. "/" .. result_cache_file_name

---@toc_entry Result Cache Consumer
---@text
--- A consumer providing a simple interface to cache and fetch test results.
--- The cache is persisted across Neovim sessions.
---@class neotest.consumers.result_cache
neotest.result_cache = {}

--- Cache test results to cache file
---@async
---@return nil
function neotest.result_cache:cache()
  nio.uv.fs_mkdir(plugin_cache, 504)
  nio.uv.fs_mkdir(consumer_cache, 504)

  local results_to_cache = {}
  for _, adapter_id in pairs(client:get_adapters()) do
    local adapter_results = client:get_results(adapter_id)
    for key, result in pairs(adapter_results) do
      if result.output then
        local output_file_cache_path = consumer_cache .. "/" .. vim.split(result.output, "/")[5]
        neotest.result_cache._cache_output_tmp_file(result.output, output_file_cache_path)
        adapter_results[key].output = output_file_cache_path
      end
    end
    results_to_cache[adapter_id] = adapter_results
  end

  lib.files.write(result_cache_file_path, vim.json.encode(results_to_cache))
end

neotest.result_cache.cache = nio.create(neotest.result_cache.cache, 1)

---@private
---@async
---@return nil
function neotest.result_cache._cache_output_tmp_file(output_file_tmp_path, output_file_cache_path)
  if not lib.files.exists(output_file_cache_path) then
    nio.uv.fs_copyfile(output_file_tmp_path, output_file_cache_path)
  end
end

--- Clear cached test results
---@async
---@return nil
function neotest.result_cache:clear()
  local cache_files = lib.files.find(consumer_cache)
  for _, file in pairs(cache_files) do
    os.remove(file)
  end
end

neotest.result_cache.clear = nio.create(neotest.result_cache.clear, 1)

--- Loads previously cached test results
---@async
---@return nil
function neotest.result_cache:fetch()
  client:load_cached_results(result_cache_file_path)
end

neotest.result_cache.fetch = nio.create(neotest.result_cache.fetch, 1)

neotest.result_cache = setmetatable(neotest.result_cache, {
  ---@param client_ neotest.Client
  __call = function(_, client_)
    client = client_
    return neotest.result_cache
  end,
})

return neotest.result_cache
