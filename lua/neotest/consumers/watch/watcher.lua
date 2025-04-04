local lib = require("neotest.lib")
local logger = require("neotest.logging")
local nio = require("nio")
local config = require("neotest.config")

---@class neotest.consumers.watch.Watcher
---@field lsp_client nio.lsp.Client
---@field autocmd_id? string
---@field tree neotest.Tree
---@field discover_positions_event nio.control.Future
local Watcher = {}

function Watcher:new(lsp_client)
  local obj = { lsp_client = lsp_client }
  self.__index = self
  return setmetatable(obj, self)
end

---@return integer[][]
function Watcher._parse_symbols(path)
  logger.debug("Parsing symbols for", path)
  local content = lib.files.read(path)
  local root, lang = lib.treesitter.get_parse_root(path, content, {})
  local query = config.watch.symbol_queries[lang]
  if not query then
    error("No symbols query for language: " .. lang)
  end
  if type(query) == "function" then
    return query(root, content, path)
  end
  local parsed_query = lib.treesitter.normalise_query(lang, query)
  local symbols = {}
  for id, node in parsed_query:iter_captures(root, content) do
    if parsed_query.captures[id] == "symbol" then
      symbols[#symbols + 1] = { node:range() }
    end
  end
  return symbols
end

---@param args neotest.consumers.watch.watcher.WatchArgs
---@return string[] paths
function Watcher:_get_linked_files(path, root_path, args)
  local symbols = lib.subprocess.enabled()
      and lib.subprocess.call(
        [[require("neotest.consumers.watch.watcher")._parse_symbols]],
        { path }
      )
    or self._parse_symbols(path)
  local path_uri = vim.uri_from_fname(path)
  local dependency_uris = {}
  logger.debug("Getting symbol definitions for", path)
  for _, range in ipairs(symbols) do
    local err, defs = self.lsp_client.request.textDocument_definition({
      position = { line = range[1], character = range[2] },
      textDocument = { uri = path_uri },
    }, nil, { timeout = 1000 })

    if err then
      logger.debug("Error getting symbol definitions for", path, ":", err)
    end

    if defs ~= nil and type(defs[1]) ~= "table" then
      defs = { defs }
    end

    for _, def in ipairs(defs or {}) do
      local index = def.uri or def.targetUri
      if index then
        dependency_uris[def.uri or def.targetUri] = true
      end
    end
  end
  local paths = { path }
  for uri in pairs(dependency_uris) do
    local p = vim.uri_to_fname(uri)
    if uri ~= path_uri and args.filter_path(p, root_path) then
      paths[#paths + 1] = p
    end
  end
  logger.debug("Found", #paths, "linked files for", path)
  return paths
end

---@class neotest.consumers.watch.watcher.WatchArgs: neotest.watch.WatchArgs
---@field filter_path fun(root: string, path: string): boolean

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
---@param args neotest.consumers.watch.watcher.WatchArgs
function Watcher:_build_dependencies(root, paths, args, dependencies)
  local count = 0
  local worker = function()
    while #paths > 0 do
      local path = table.remove(paths)

      if not dependencies[path] then
        count = count + 1
        dependencies[path] = {}
        local path_results = self:_get_linked_files(path, root, args)
        dependencies[path] = path_results

        for _, p in ipairs(path_results) do
          if not dependencies[p] then
            paths[#paths + 1] = p
          end
        end
      end
    end
  end
  local num_workers = 4
  local workers = {}
  for _ = 1, num_workers do
    workers[#workers + 1] = worker
  end
  nio.gather(workers)
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

---@param tree neotest.Tree
---@param args neotest.consumers.watch.watcher.WatchArgs
function Watcher:watch(tree, args)
  local run = require("neotest").run
  local paths = self:_files_in_tree(tree)

  local start = vim.loop.now()
  local dependencies = {}
  self:_build_dependencies(tree:root():data().path, paths, args, dependencies)
  local elapsed = vim.loop.now() - start
  logger.debug("Built dependencies in", elapsed, "ms for", tree:data().id, ":", dependencies)
  local dependants = self:_build_dependants(dependencies)

  self.tree = tree
  self.discover_positions_event = nio.control.future()

  self.autocmd_id = nio.api.nvim_create_autocmd("BufWritePost", {
    callback = function(autocmd_args)
      if type(args.run_predicate) == "function" and not args.run_predicate(autocmd_args.buf) then
        return
      end
      nio.run(function()
        local path = nio.fn.expand(nio.api.nvim_buf_get_name(autocmd_args.buf), ":p")

        local buf_dependants = dependants[path]
        if not buf_dependants then
          return
        end

        if path == tree:data().path then
          self.discover_positions_event.wait()
        end
        self.discover_positions_event = nio.control.future()

        if tree:data().type ~= "dir" then
          run.run(vim.tbl_extend("keep", { tree:data().id }, args))
        else
          for _, dep in ipairs(buf_dependants) do
            run.run(vim.tbl_extend("keep", { dep }, args))
          end
        end

        if dependencies[path] then
          dependencies[path] = nil
          self:_build_dependencies(tree:root():data().path, { path }, args, dependencies)
          logger.debug("Rebuilt dependencies for", tree:data().id, ":", dependencies)
          dependants = self:_build_dependants(dependencies)
        end
      end, function(success, err)
        if not success then
          lib.notify(("Error watching %s: %s"):format(tree:data().name, err), vim.log.levels.ERROR)
        end
      end)
    end,
  })

  run.run(vim.tbl_extend("keep", { tree:data().id }, args))
  logger.info("Starting watch of", tree:data().id)
end

function Watcher:stop_watch()
  if not self.autocmd_id then
    logger.warn("Watcher never started, can't stop it")
    return
  end
  logger.info("Stopping watch")
  nio.api.nvim_del_autocmd(self.autocmd_id)
end

return Watcher
