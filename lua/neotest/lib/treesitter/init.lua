local async = require("plenary.async")
local types = require("neotest.types")
local FIFOQueue = types.FIFOQueue
local Tree = types.Tree
local ts_parsers = require("nvim-treesitter.parsers")

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
---@param buf integer
---@param root table
---@return FIFOQueue
local function collect(file_path, query, buf, root, opts)
  local sep = require("neotest.lib").files.sep
  local nodes = FIFOQueue()
  local path_elems = vim.split(file_path, sep, { plain = true })
  nodes:push({
    type = "file",
    path = file_path,
    name = path_elems[#path_elems],
    range = { root:range() },
  })
  vim.tbl_add_reverse_lookup(query.captures)
  for _, match in query:iter_matches(root, buf) do
    local type = get_query_type(query, match)
    if type then
      ---@type string
      local name = vim.treesitter.get_node_text(match[query.captures[type .. ".name"]], buf)
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

---@param pos_a NeotestPosition
---@param pos_b NeotestPosition
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

---@param positions FIFOQueue
---@return table[] Nested lists to be parsed as a tree object
local function parse_tree(positions, namespaces, opts)
  ---@type NeotestPosition
  local parent = positions:pop()
  if not parent then
    return nil
  end
  parent.id = parent.type == "file" and parent.path
    or table.concat(vim.tbl_flatten({ parent.path, namespaces, parent.name }), "::")
  local current_level = { parent }
  local child_namespaces = vim.list_extend({}, namespaces)
  if parent.type == "namespace" then
    child_namespaces[#child_namespaces + 1] = parent.name
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

---@param pos NeotestPosition
---@return string
local function position_key(pos)
  return pos.id
end

---@parma file_path string
---@param query table | string
---@param buf integer
---@return Tree
local function parse_buf_positions(file_path, query, buf, opts)
  local ft = require("neotest.lib").files.detect_filetype(file_path)
  local lang = ts_parsers.ft_to_lang(ft)
  local parser = ts_parsers.get_parser(buf, lang)
  local root = parser:parse()[1]:root()
  if type(query) == "string" then
    query = vim.treesitter.parse_query(ft, query)
  end
  local positions = collect(file_path, query, buf, root, opts)
  local structure = parse_tree(positions, {}, opts)
  local tree = Tree.from_list(structure, position_key)
  return tree
end

---@async
---@param file_path string
---@param query string | vim.treesitter.Query
---@param opts table
---@return Tree
function M.parse_positions(file_path, query, opts)
  async.util.sleep(10)
  opts = vim.tbl_extend("force", {
    nested_tests = false, -- Allow nested namespaces
    require_namespaces = false, -- Only allow tests within namespaces
  }, opts or {})
  local lines = require("neotest.lib").files.read_lines(file_path)
  if #lines == 0 then
    return
  end
  local temp_buf = async.api.nvim_create_buf(false, true)
  async.api.nvim_buf_set_lines(temp_buf, 0, -1, false, lines)
  local result = parse_buf_positions(file_path, query, temp_buf, opts)
  async.api.nvim_buf_delete(temp_buf, { force = true })
  return result
end

return M
