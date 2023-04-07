local lib = require("neotest.lib")
local logger = require("neotest.logging")
local nio = require("nio")
local config = require("neotest.config")
local f = lib.func_util

local ItemKind = {
  Value = 12,
}

---@class neotest.consumers.watch.Watcher
---@field lsp_client nio.lsp.Client
---@field watching? string
---@field autocmd_id? string
local Watcher = {}

function Watcher:new(lsp_client)
  local obj = { lsp_client = lsp_client }
  self.__index = self
  return setmetatable(obj, self)
end

---@param pos neotest.Position
---@param symbol nio.lsp.types.DocumentSymbol|nio.lsp.types.SymbolInformation
function Watcher:_contains(pos, symbol)
  return pos.type == "file"
    or pos.range[1] >= symbol.range.start.line
      and pos.range[2] >= symbol.range.start.character
      and pos.range[3] <= symbol.range["end"].line
      and pos.range[4] <= symbol.range["end"].character
end

---@return nio.lsp.types.DocumentSymbol[]|nio.lsp.types.SymbolInformation[]
function Watcher:_get_value_document_symbols(uri)
  local err, symbols =
    self.lsp_client.request.textDocument_documentSymbol({ textDocument = { uri = uri } })
  assert(not err and symbols, err)
  local to_check = vim.list_extend({}, symbols)
  local valid_symbols = {}
  while #to_check > 0 do
    ---@type nio.lsp.types.DocumentSymbol|nio.lsp.types.SymbolInformation
    local symbol = table.remove(to_check)
    if symbol.kind == ItemKind.Value then
      valid_symbols[#valid_symbols + 1] = symbol
    end
    if symbol.children then
      for _, child in ipairs(symbol.children) do
        table.insert(to_check, child)
      end
    end
  end
  return valid_symbols
end

---@param symbol { selectionRange: {start: {line: number, character: number}}}
function Watcher:_get_call_items(uri, symbol)
  local _, call_hierarchy_items = self.lsp_client.request.textDocument_prepareCallHierarchy({
    position = {
      line = symbol.selectionRange.start.line,
      character = symbol.selectionRange.start.character,
    },
    textDocument = { uri = uri },
  })
  return call_hierarchy_items
end

---@param item nio.lsp.types.CallHierarchyItem
function Watcher:_item_key(item)
  return ("%s:%s:%s:%s:%s"):format(
    item.uri,
    item.range.start.line,
    item.range.start.character,
    item.range["end"].line,
    item.range["end"].character
  )
end

function Watcher:_get_linked_files_by_calls(path)
  local uri = vim.uri_from_fname(path)
  local uris = {}

  local symbols = self:_get_value_document_symbols(uri)
  ---@type nio.lsp.types.CallHierarchyItem[]
  local call_items = {}
  for _, symbol in ipairs(symbols) do
    vim.list_extend(call_items, self:_get_call_items(uri, symbol))
  end
  local calls_checked = {}

  while #call_items > 0 do
    local call_item = table.remove(call_items)
    calls_checked[self:_item_key(call_item)] = true
    local _, call_hierarchy =
      self.lsp_client.request.callHierarchy_outgoingCalls({ item = call_item })

    for _, call in ipairs(call_hierarchy or {}) do
      uris[call.to.uri] = true
      if call.to.uri == uri and not calls_checked[self:_item_key(call.to)] then
        call_items[#call_items + 1] = call.to
      end
    end
  end

  return vim.tbl_keys(uris)
end

---@param args neotest.consumers.watch.WatchArgs
function Watcher:_get_linked_files_by_imports(path, args)
  local content = lib.files.read(path)
  local root, lang = lib.treesitter.get_parse_root(path, content, {})
  local query = args.queries[lang]
  if not query then
    logger.warn("No query for language: " .. lang)
    return {}
  end
  local parsed_query = lib.treesitter.normalise_query(lang, query)
  local symbols = {}
  for id, node in parsed_query:iter_captures(root, content) do
    if parsed_query.captures[id] == "symbol" then
      symbols[#symbols + 1] = { node:range() }
    end
  end
  local uri = vim.uri_from_fname(path)
  local dependency_uris = {}
  for _, range in ipairs(symbols) do
    local _, defs = self.lsp_client.request.textDocument_definition({
      position = { line = range[1], character = range[2] },
      textDocument = { uri = uri },
    })
    for _, def in ipairs(defs or {}) do
      dependency_uris[def.uri] = true
    end
  end
  return vim.tbl_keys(dependency_uris)
end

---@class neotest.consumers.watch.WatchArgs
---@field method "calls"|"imports"
---@field limit_to_project boolean
---@field queries table<string, string>

---@param args neotest.consumers.watch.WatchArgs
function Watcher:_get_linked_files(path, project_uri, args)
  local uris
  if args.method == "imports" then
    uris = self:_get_linked_files_by_imports(path, args)
  end
  if uris == nil then
    uris = self:_get_linked_files_by_calls(path)
  end

  local files = { path }
  local path_uri = vim.uri_from_fname(path)
  for _, uri in ipairs(uris) do
    if uri ~= path_uri and (not args.limit_to_project or vim.startswith(uri, project_uri)) then
      files[#files + 1] = vim.uri_to_fname(uri)
    end
  end

  return files
end

---@paam tree neotest.Tree
function Watcher:_files_in_tree(tree)
  if tree:data().type ~= "dir" then
    return { tree:data().path }
  end
  local paths = {}
  for _, pos in
    tree:iter({
      continue = function(node)
        return node:data().type == "dir"
      end,
    })
  do
    if pos.type == "file" then
      paths[#paths + 1] = pos.path
    end
  end
  return paths
end

---@param root string
---@param paths string[]
---@param args neotest.consumers.watch.WatchArgs
function Watcher:_build_dependencies(root, paths, args)
  local project_uri = vim.uri_from_fname(root)

  local results = nio.gather(f.map_list(function(_, path)
    return function()
      return self:_get_linked_files(path, project_uri, args)
    end
  end, paths))

  local dependencies = {}
  for i, path in ipairs(paths) do
    dependencies[path] = results[i]
  end
  return dependencies
end

---@param dependencies table<string, string[]>
function Watcher:_build_dependants(dependencies)
  local dependants = {}
  for path, deps in pairs(dependencies) do
    for _, dep in ipairs(deps) do
      dependants[dep] = dependants[dep] or {}
      dependants[dep][#dependants[dep] + 1] = path
    end
  end
  return dependants
end

function Watcher:watch(tree, run_args)
  local run = require("neotest").run
  local paths = self:_files_in_tree(tree)
  ---@type neotest.consumers.watch.WatchArgs
  local watch_args = {
    method = "imports",
    queries = config.watch.import_queries,
    limit_to_project = true,
  }

  local dependencies = self:_build_dependencies(tree:root():data().path, paths, watch_args)
  local dependants = self:_build_dependants(dependencies)

  self.autocmd_id = nio.api.nvim_create_autocmd("BufWritePost", {
    callback = function(args)
      nio.run(function()
        local path = nio.fn.expand(nio.api.nvim_buf_get_name(args.buf), ":p")

        local buf_dependants = dependants[path]
        if not buf_dependants then
          return
        end

        if tree:data().type ~= "dir" then
          run.run(vim.tbl_extend("keep", { tree:data().id }, run_args))
        else
          for _, dep in ipairs(buf_dependants) do
            run.run(vim.tbl_extend("keep", { dep }, run_args))
          end
        end

        if dependencies[path] then
          dependencies[path] = self:_build_dependencies({ path })[path]
          dependants = self:_build_dependants(dependencies)
        end
      end)
    end,
  })

  self.watching = tree:data().id
  run.run(vim.tbl_extend("keep", { tree:data().id }, run_args))
  logger.info("Starting watch of", self.watching)
  logger.debug("Watch dependencies", dependencies)
  lib.notify(("Watching %s"):format(tree:data().name))
end

function Watcher:stop_watch()
  if not self.watching then
    return
  end
  logger.info("Stopping watch of", self.watching)
  nio.api.nvim_del_autocmd(self.autocmd_id)
  self.watching = nil
end

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

---@param run_args? neotest.run.RunArgs|string
return function(run_args)
  run_args = run_args or {}
  if type(run_args) == "string" then
    run_args = { run_args }
  end
  local run = require("neotest").run
  local tree = run.get_tree_from_args(run_args, false)
  if not tree then
    lib.notify(
      ("No position found with args %s"):format(vim.inspect(run_args)),
      vim.log.levels.WARN
    )
    return
  end
  local lsp_client = get_lsp_client(tree)
  if not lsp_client then
    lib.notify(
      "No valid LSP client found for watching. Ensure that at least one test file is open and has an LSP client attached."
    )
    return
  end

  local watcher = Watcher:new(lsp_client)

  watcher:watch(tree, run_args)
  return watcher
end
