local nio = require("nio")

---@private
---@type neotest.Client
local client

local neotest = {}

local _cache_file_dir = vim.fn.stdpath("cache") .. "/neotest"
local _cache_file_name = "results.json"
local _cache_file_path = _cache_file_dir .. "/" .. _cache_file_name

---@toc_entry Result Cache Consumer
---@text
--- A consumer providing a simple interface to cache and fetch test results.
--- The cache is persisted across Neovim sessions.
---@class neotest.consumers.result_cache
neotest.result_cache = {}

--- Cache test results to cache file
---@return nil
function neotest.result_cache:cache()
  local results_to_cache = {}
  for _, adapter_id in pairs(client:get_adapters()) do
    results_to_cache[adapter_id] = client:get_results(adapter_id)
  end
  vim.fn.mkdir(_cache_file_dir, "p")
  vim.fn.writefile({ vim.json.encode(results_to_cache) }, _cache_file_path)
end

neotest.result_cache.cache = nio.create(neotest.result_cache.cache, 1)

--- Clear cached test results
---@return nil
function neotest.result_cache:clear()
  vim.fn.delete(_cache_file_path)
end

neotest.result_cache.clear = nio.create(neotest.result_cache.clear, 1)

--- Loads previously cached results
---@return nil
function neotest.result_cache:fetch()
  client:load_cached_results(_cache_file_path)
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
