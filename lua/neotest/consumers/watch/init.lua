local lib = require("neotest.lib")
local config = require("neotest.config")
local logger = require("neotest.logging")
local nio = require("nio")
local Watcher = require("neotest.consumers.watch.watcher")

local watchers = {}

local neotest = {}

---@toc_entry Watch Consumer
---@text
--- Allows watching tests and re-running them whenever related files are
--- changed. When watching a directory, all files are run in separate processes.
--- Otherwise the tests are run in the same process (if allowed by the adapter).
---
--- Related files are determined through an LSP client through a "best effort"
--- which means there are cases where a file may not be determined as related
--- despite it having an effect on a test.
---@class neotest.consumers.watch
neotest.watch = {}

local function get_valid_client_id(bufnr)
  local sync_clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  for _, client in ipairs(sync_clients) do
    ---@type nio.lsp.types.ServerCapabilities
    local caps = client.server_capabilities
    if caps.definitionProvider then
      logger.debug("Found client", client.name, "for watch")
      return client.id
    end
  end
end

local function get_lsp_client(tree)
  for _, buf in ipairs(nio.api.nvim_list_bufs()) do
    local path = nio.fn.fnamemodify(nio.api.nvim_buf_get_name(buf), ":p")
    if tree:get_key(path) then
      local client_id = get_valid_client_id(buf)
      if client_id then
        return nio.lsp.client(client_id)
      end
    end
  end
end

local ignored_dirs = {
  "venv",
  ".venv",
  "node_modules",
}

---@type neotest.consumers.watch.watcher.WatchArgs
---@private
local default_args = {
  symbol_queries = config.watch.symbol_queries,
  filter_path = config.watch.filter_path or function(path, root)
    if not vim.startswith(path, root) then
      return false
    end
    for _, dir in ipairs(ignored_dirs) do
      if vim.startswith(path, root .. lib.files.sep .. dir) then
        return false
      end
    end
    return true
  end,
}

--- Watch a position and run it whenever related files are changed.
--- Arguments are the same as the `neotest.run.run`, which allows
--- for custom runner arguments, env vars, strategy etc. If a position is
--- already being watched, the existing watcher will be stopped.
---@param args? neotest.run.RunArgs|string
neotest.watch.watch = nio.create(function(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  args = vim.tbl_extend("keep", args, default_args)

  local run = require("neotest").run
  local tree = run.get_tree_from_args(args, false)

  if not tree then
    lib.notify(("No position found with args %s"):format(vim.inspect(args)), vim.log.levels.ERROR)
    return
  end

  local lsp_client = get_lsp_client(tree)
  if not lsp_client then
    lib.notify(
      "No valid LSP client found for watching. Ensure that at least one test file is open and has an LSP client attached.",
      vim.log.levels.ERROR
    )
    return
  end

  local watcher = Watcher:new(lsp_client)

  local pos_id = tree:data().id
  if watchers[pos_id] then
    neotest.watch.stop(pos_id)
  end
  watchers[pos_id] = watcher

  nio.run(function()
    watcher:watch(tree, args)
  end)
end, 1)

--- Stop watching a position. If no position is provided, all watched positions are stopped.
function neotest.watch.stop(pos_id)
  if not pos_id then
    for watched in pairs(watchers) do
      neotest.watch.stop(watched)
    end
    return
  end

  if not watchers[pos_id] then
    lib.notify(("%s is not being watched"):format(pos_id), vim.log.levels.WARN)
    return
  end

  watchers[pos_id]:stop_watch()
  watchers[pos_id] = nil
end

--- Check if a position is being watched.
---@param position_id string
---@return boolean
function neotest.watch.is_watching(position_id)
  return watchers[position_id] ~= nil
end

neotest.watch = setmetatable(neotest.watch, {
  __call = function()
    return neotest.watch
  end,
})

return neotest.watch
