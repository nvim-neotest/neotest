local logger = require("neotest.logging")
local async = require("neotest.async")
local lib = require("neotest.lib")

local Tree = require("neotest.types").Tree
local child_failed = false

local neotest = { lib = {} }

---@toc_entry Library: Treesitter
---@text
--- Functions to help parse files with treesitter, optimised for test parsing.
---@class neotest.lib.treesitter
neotest.lib.treesitter = {}

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
---@param opts neotest.lib.treesitter.ParseOptions
---@return table[]
---@private
local function collect(file_path, query, source, root, opts)
  local sep = lib.files.sep
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
function neotest.lib.treesitter.fast_parse(lang_tree)
  if lang_tree._valid then
    return lang_tree._trees
  end

  local parser = lang_tree._parser
  local old_trees = lang_tree._trees
  return parser:parse(old_trees[1], lang_tree._source)
end

---@class neotest.lib.treesitter.ParseOptions : neotest.lib.positions.ParseOptions
---@field fast boolean Use faster parsing (Should be unchanged unless injections are needed)
---@field build_position fun(file_path: string, source: string, captured_nodes: table<string, userdata>): neotest.Position|neotest.Position[]|nil Builds one or more positions from the captured nodes from a query match.

--- Build a parsed Query object from a string
---@param lang string
---@param query table|string
---@return table
function neotest.lib.treesitter.normalise_query(lang, query)
  if type(query) == "string" then
    query = vim.treesitter.parse_query(lang, query)
  end
  return query
end

--- Return a treesitter tree root for file_path and the TreeSitter lang value for it
---@param file_path string
---@param content string
---@param opts neotest.lib.treesitter.ParseOptions
---@return userdata,string
function neotest.lib.treesitter.get_parse_root(file_path, content, opts)
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
  local root
  if fast then
    root = neotest.lib.treesitter.fast_parse(lang_tree):root()
  else
    root = lang_tree:parse()[1]:root()
  end
  return root, lang
end

--- Same as `parse_positions` but uses the provided content instead of reading file.
--- Do not use this directly unless you have a good reason. `parse_positions` is preferred
--- because it will parse in a subprocess and thus will never block the current editor instance.
---@param file_path string
---@param content string
---@param query table|string
---@param opts neotest.lib.treesitter.ParseOptions
---@return neotest.Tree
function neotest.lib.treesitter.parse_positions_from_string(file_path, content, query, opts)
  ---@type neotest.lib.treesitter.ParseOptions
  opts = vim.tbl_extend("force", { build_position = build_position }, opts or {})
  if opts.build_position then
    if type(opts.build_position) == "string" then
      local loaded, err = loadstring("return " .. opts.build_position)
      assert(loaded, ("Couldn't parse `build_position` option: %s"):format(err))
      opts.build_position = loaded()
    end
  end
  if opts.position_id then
    if type(opts.position_id) == "string" then
      local loaded, err = loadstring("return " .. opts.position_id)
      assert(loaded, ("Couldn't parse `position_id` option: %s"):format(err))
      opts.position_id = loaded()
    end
  end
  local root, lang = neotest.lib.treesitter.get_parse_root(file_path, content, opts)
  local parsed_query = neotest.lib.treesitter.normalise_query(lang, query)
  local positions = collect(file_path, parsed_query, content, root, opts)
  return lib.positions.parse_tree(positions, opts)
end

--- Read a file's contents from disk and parse test positions using the given query.
--- Executed in a subprocess to avoid blocking the editor if possible.
--- Since functions can't be serialised for RPC the build_position and position_id options
--- can be strings that will evaluate to globally referencable functions
--- (e.g. `'require("my_adapter")._build_position'`).
---@async
---@param file_path string
---@param query string
---@param opts neotest.lib.treesitter.ParseOptions
---@return neotest.Tree
function neotest.lib.treesitter.parse_positions(file_path, query, opts)
  opts = opts or {}
  if child_failed or not lib.subprocess.enabled() then
    return neotest.lib.treesitter._parse_positions(file_path, query, opts)
  end

  if type(opts.build_position) == "function" or type(opts.position_id) == "function" then
    logger.warn(
      "Using `build_position` or `position_id` functions with subprocess parsing is not supported, switch to using strings for remote calls"
    )
    return neotest.lib.treesitter._parse_positions(file_path, query, opts)
  end

  local raw_result, err = lib.subprocess.call(
    "require('neotest.lib').treesitter._parse_positions",
    { file_path, query, opts, true }
  )
  if err then
    logger.error("Child process failed to parse, disabling suprocess usage")
    child_failed = true
    return neotest.lib.treesitter._parse_positions(file_path, query, opts)
  end
  local tree = Tree.from_list(raw_result, function(pos)
    return pos.id
  end)
  return tree
end

---@private
function neotest.lib.treesitter._parse_positions(file_path, query, opts, to_list)
  local content = lib.files.read(file_path)
  local tree = neotest.lib.treesitter.parse_positions_from_string(file_path, content, query, opts)
  if to_list then
    return tree:to_list()
  end
  return tree
end

return neotest.lib.treesitter
