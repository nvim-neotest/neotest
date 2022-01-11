local async = require("plenary.async")
local logger = require("neotest.logging")
local lib = require("neotest.lib")

local M = {}

---@type table<string, NeotestAdapter>
local adapters = {}

function M.set_adapters(a)
  adapters = a
end

local function get_current_adapter_from_cwd()
  local files = lib.files.find({ async.fn.getcwd() })
  for _, adapter in pairs(adapters) do
    for _, file in pairs(files) do
      if adapter.is_test_file(file) then
        return adapter
      end
    end
  end
end

local function get_adapter_from_open_bufs()
  local buffers = async.api.nvim_list_bufs()
  for _, adapter in pairs(adapters) do
    for _, bufnr in pairs(buffers) do
      if adapter.is_test_file(async.fn.fnamemodify(async.fn.bufname(bufnr), ":p")) then
        return adapter
      end
    end
  end
end

local function get_adapter_from_file_path(file_path)
  for _, adapter in pairs(adapters) do
    if adapter.is_test_file(file_path) then
      return adapter
    end
  end
end

local adapter = nil

function M.get_adapter(opts)
  local file_path = opts.file_path
  if not adapter and file_path then
    adapter = get_adapter_from_file_path(file_path)
  end
  if not adapter then
    adapter = get_adapter_from_open_bufs()
  end
  if opts.from_dir and not adapter then
    adapter = get_current_adapter_from_cwd()
  end
  if adapter then
    logger.debug("Using adapter " .. adapter.name)
  else
    logger.info("No adapter found")
  end
  return adapter
end

return M
