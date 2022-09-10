local async = require("neotest.async")

local M = {}

local function get_match_type(captured_nodes)
  if captured_nodes["test.name"] then
    return "test"
  end
  if captured_nodes["namespace.name"] then
    return "namespace"
  end
end

local function build_position(file_path, source, captured_nodes)
  local match_type = get_match_type(captured_nodes)
  if match_type then
    ---@type string
    local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
    local definition = captured_nodes[match_type .. ".definition"]

    return {
      type = match_type,
      path = file_path,
      name = name,
      range = { definition:range() },
    }
  end
end

---@param file_path string
---@param query table
---@param source string
---@param root table
---@param opts neotest.treesitter.ParseOptions
---@return table[]
local function collect(file_path, query, source, root, opts)
  local sep = require("neotest.lib").files.sep
  local path_elems = vim.split(file_path, sep, { plain = true })
  local nodes = {
    {
      type = "file",
      path = file_path,
      name = path_elems[#path_elems],
      range = { root:range() },
    },
  }
  for _, match in query:iter_matches(root, source) do
    local captured_nodes = {}
    for i, capture in ipairs(query.captures) do
      captured_nodes[capture] = match[i]
    end
    local res = opts.build_position(file_path, source, captured_nodes)
    if res then
      if res[1] then
        for _, pos in ipairs(res) do
          nodes[#nodes + 1] = pos
        end
      else
        nodes[#nodes + 1] = res
      end
    end
  end

  return nodes
end

--- Injections take a long time to run and are not needed.
--- This does only the required parsing
--- Replaces `LanguageTree:parse`
--- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/treesitter/languagetree.lua
function M.fast_parse(lang_tree)
  if lang_tree._valid then
    return lang_tree._trees
  end

  local parser = lang_tree._parser
  local old_trees = lang_tree._trees
  return parser:parse(old_trees[1], lang_tree._source)
end

---@class neotest.treesitter.ParseOptions : neotest.positions.ParseOptions
---@field fast boolean Use faster parsing (Should be unchanged unless injections are needed)
local ParseOptions = {}
---Builds one or more positions from the captured nodes from a query match.
---@param file_path string Path to file being parsed
---@param source string Contents of file being parsed
---@param captured_nodes table<string, userdata> Captured nodes, indexed by capture name (e.g. `test.name`)
---@return neotest.Position | neotest.Position[] | nil
function ParseOptions.build_position(file_path, source, captured_nodes) end

---Same as `parse_positions` but uses the provided content instead of reading file.
---@parma file_path string
---@param content string
---@param query table | string
---@param opts neotest.treesitter.ParseOptions
---@return neotest.Tree
function M.parse_positions_from_string(file_path, content, query, opts)
  opts = vim.tbl_extend("force", { build_position = build_position }, opts or {})
  local lib = require("neotest.lib")
  local fast = opts.fast ~= false
  local ft = lib.files.detect_filetype(file_path)
  local lang = require("nvim-treesitter.parsers").ft_to_lang(ft)
  async.util.scheduler()
  local lang_tree = vim.treesitter.get_string_parser(
    content,
    lang,
    --- Providing an injection query for the lang prevents
    --- it from trying to read the query from runtime files
    fast and { injections = { [lang] = "" } } or {}
  )
  if type(query) == "string" then
    query = vim.treesitter.parse_query(lang, query)
  end

  local root
  if fast then
    root = M.fast_parse(lang_tree):root()
  else
    root = lang_tree:parse()[1]:root()
  end
  local positions = collect(file_path, query, content, root, opts)
  return lib.positions.parse_tree(positions, opts)
end

---Read a file's contents from disk and parse test positions using the given query.
---See lib.positions.parse_tree for more options options
---@async
---@param file_path string
---@param query string | vim.treesitter.Query
---@param opts neotest.treesitter.ParseOptions
---@return neotest.Tree
function M.parse_positions(file_path, query, opts)
  async.util.sleep(10) -- Prevent completely hogging main thread
  local content = require("neotest.lib").files.read(file_path)
  return M.parse_positions_from_string(file_path, content, query, opts)
end

return M
