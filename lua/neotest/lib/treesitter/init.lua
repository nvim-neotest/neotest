local async = require("neotest.async")
local types = require("neotest.types")
local FIFOQueue = types.FIFOQueue
local Tree = types.Tree

local M = {}

local function get_query_type(query, match)
  for id, _ in pairs(match) do
    local name = query.captures[id]
    if name == "test.name" or name == "test.definition" then
      return "test"
    end
    if name == "namespace.name" or name == "namespace.definition" then
      return "namespace"
    end
  end
  return nil
end

---@param file_path string
---@param query table
---@param source string
---@param root table
---@return neotest.FIFOQueue
local function collect(file_path, query, source, root)
  local sep = require("neotest.lib").files.sep
  local nodes = FIFOQueue()
  local path_elems = vim.split(file_path, sep, { plain = true })
  nodes:push({
    type = "file",
    path = file_path,
    name = path_elems[#path_elems],
    range = { root:range() },
  })
  pcall(vim.tbl_add_reverse_lookup, query.captures)
  for _, match in query:iter_matches(root, source) do
    local type = get_query_type(query, match)
    if type then
      ---@type string
      local name = vim.treesitter.get_node_text(match[query.captures[type .. ".name"]], source)
      local definition = match[query.captures[type .. ".definition"]]

      nodes:push({
        type = type,
        path = file_path,
        name = name,
        range = { definition:range() },
      })
    end
  end
  return nodes
end

---@param pos_a neotest.Position
---@param pos_b neotest.Position
local function contains(pos_a, pos_b)
  local a_s_r, a_s_c, a_e_r, a_e_c = unpack(pos_a.range)
  local b_s_r, b_s_c, b_e_r, b_e_c = unpack(pos_b.range)
  if a_s_r > b_s_r or a_e_r < b_e_r then
    return false
  end
  if a_s_r == b_s_r and a_s_c > b_s_c then
    return false
  end
  if a_e_r == b_e_r and a_e_c < b_e_c then
    return false
  end
  return true
end

---@param positions neotest.FIFOQueue
---@return table[] Nested lists to be parsed as a tree object
local function parse_tree(positions, namespaces, opts)
  ---@type neotest.Position
  local parent = positions:pop()
  if not parent then
    return nil
  end
  parent.id = parent.type == "file" and parent.path or opts.position_id(parent, namespaces)
  local current_level = { parent }
  local child_namespaces = vim.list_extend({}, namespaces)
  if parent.type == "namespace" or (opts.nested_tests and parent.type == "test") then
    child_namespaces[#child_namespaces + 1] = parent
  end
  while true do
    local next_pos = positions:peek()
    if not next_pos or not contains(parent, next_pos) then
      -- Don't preserve empty namespaces
      if #current_level == 1 and parent.type == "namespace" then
        return nil
      end
      if opts.require_namespaces and parent.type == "test" and #namespaces == 0 then
        return nil
      end
      return current_level
    end

    local sub_tree = parse_tree(positions, child_namespaces, opts)
    if opts.nested_tests or parent.type ~= "test" then
      current_level[#current_level + 1] = sub_tree
    end
  end
end

---@param pos neotest.Position
---@return string
local function position_key(pos)
  return pos.id
end

---@parma file_path string
---@param query table | string
---@param content string
---@return neotest.Tree
local function parse_positions(file_path, query, content, opts)
  local ft = require("neotest.lib").files.detect_filetype(file_path)
  local lang = require("nvim-treesitter.parsers").ft_to_lang(ft)
  async.util.scheduler()
  local parser = vim.treesitter.get_string_parser(content, lang)
  if type(query) == "string" then
    query = vim.treesitter.parse_query(lang, query)
  end
  local root = parser:parse()[1]:root()
  local positions = collect(file_path, query, content, root)
  local structure = parse_tree(positions, {}, opts)
  local tree = Tree.from_list(structure, position_key)
  return tree
end

---Read a file's contents from disk and parse test positions using the given query.
---@async
---@param file_path string
---@param query string | vim.treesitter.Query
---@param opts table
---@return neotest.Tree
function M.parse_positions(file_path, query, opts)
  async.util.sleep(10) -- Prevent completely hogging main thread
  local content = require("neotest.lib").files.read(file_path)
  return M.parse_positions_from_string(file_path, content, query, opts)
end

---Same as `parse_positions` but uses the provided content instead of reading file.
function M.parse_positions_from_string(file_path, content, query, opts)
  opts = vim.tbl_extend("force", {
    nested_tests = false, -- Allow nested tests
    require_namespaces = false, -- Only allow tests within namespaces
    ---@param position neotest.Position The position to return an ID for
    ---@param parents neotest.Position[] Parent positions for the position
    position_id = function(position, namespaces)
      return table.concat(
        vim.tbl_flatten({
          position.path,
          vim.tbl_map(function(pos)
            return pos.name
          end, namespaces),
          position.name,
        }),
        "::"
      )
    end,
  }, opts or {})
  local results = parse_positions(file_path, query, content, opts)
  return results
end

return M
