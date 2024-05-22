local Path = require("plenary.path")
local Tree = require("neotest.types").Tree
local utils = require("neotest.utils")

local neotest = { lib = {} }

---@toc_entry Library: Positions
---@text
--- Functions for interacting with positions and position trees
---@class neotest.lib.positions
neotest.lib.positions = {}

--- Get the nearest position to the given line in the provided file tree
---@param tree neotest.Tree
---@param line integer
---@return neotest.Tree
neotest.lib.positions.nearest = function(tree, line)
  local nearest = tree
  for _, node in tree:iter_nodes() do
    local pos = node:data()
    if pos.range then
      if line >= pos.range[1] then
        nearest = node
      else
        return nearest
      end
    end
  end
  return nearest
end

--- Check if a positions is contained by another. Assumes that both positions exist on the file system, meaning they are files,
--- directories or have a range attribute specified.
---@param parent neotest.Position
---@param child neotest.Position
---@return boolean
neotest.lib.positions.contains = function(parent, child)
  if parent.type == "dir" then
    return parent.path == child.path
      or vim.startswith(child.path, parent.path .. require("neotest.lib.file").sep)
  end
  if child.type == "dir" then
    return false
  end
  if parent.type == "file" then
    return parent.path == child.path
  end
  if child.type == "file" then
    return false
  end
  return parent.range[1] <= child.range[1] and parent.range[3] >= child.range[3]
end

---@param position neotest.Position
---@return neotest.Position
local function get_parent(position)
  if position.type ~= "dir" and position.type ~= "file" then
    error(string.format("Cannot get the parent of %s position", position.type))
  end
  if position.path == Path.path.root(position.path) then
    return position
  end
  local pieces = vim.split(position.path, Path.path.sep)
  table.remove(pieces)
  local parent_path = table.concat(pieces, Path.path.sep)

  return {
    type = "dir",
    id = parent_path,
    path = parent_path,
    name = pieces[#pieces],
    range = nil,
  }
end

---@param tree neotest.Tree
---@return neotest.Tree
local function wrap_with_parent(tree)
  local parent = get_parent(tree:data())
  local parent_tree = Tree.from_list({ parent }, function(pos)
    return pos.id
  end)
  parent_tree:add_child(tree:data().id, tree)
  return parent_tree
end

---@param dir_tree neotest.Tree
---@param new_tree neotest.Tree
---@return neotest.Tree
local function get_or_create_parent_node(dir_tree, new_tree)
  local parent = get_parent(new_tree:data())
  local parent_tree = dir_tree:get_key(parent.id)
  if not parent_tree then
    parent_tree = Tree.from_list({ parent }, function(pos)
      return pos.id
    end)
    local grandparent_tree = get_or_create_parent_node(dir_tree, parent_tree)
    grandparent_tree:add_child(new_tree:data().id, parent_tree)
    parent_tree = dir_tree:get_key(parent.id)
    assert(parent_tree ~= nil)
  end
  return parent_tree
end

---@param tree neotest.Tree
---@param node neotest.Tree
local function replace_node(tree, node)
  local existing = tree:get_key(node:data().id)
  if not existing then
    local parent = get_or_create_parent_node(tree, node)
    parent:add_child(node:data().id, node)
    return
  end

  -- Find parent node and replace child reference
  local parent = existing:parent()
  if not parent then
    -- If there is no parent, then the tree describes the same position as node,
    -- and is replaced in its entirety
    tree._children = node._children
    tree._nodes = node._nodes
    tree._data = node._data
    return
  end

  for i, child in pairs(parent._children) do
    if node:data().id == child:data().id then
      parent._children[i] = node
      break
    end
  end
  node._parent = parent

  -- Remove node and all descendants
  for _, pos in existing:iter() do
    tree._nodes[pos.id] = nil
  end

  -- Replace nodes map in new node and descendants
  for _, n in node:iter_nodes() do
    tree._nodes[n:data().id] = n
    n._nodes = tree._nodes
  end
end

---@param dir_tree neotest.Tree
---@param file_tree neotest.Tree
local function update_file_node(dir_tree, file_tree, force)
  local existing = dir_tree:get_key(file_tree:data().id)
  if force or not existing or (#existing:children() == 0 and #file_tree:children() > 0) then
    replace_node(dir_tree, file_tree)
  end
end

---@param orig neotest.Tree Directory tree
---@param new neotest.Tree File or directory tree
---@private
neotest.lib.positions.merge = function(orig, new)
  if
    not neotest.lib.positions.contains(orig:data(), new:data())
    and not neotest.lib.positions.contains(new:data(), orig:data())
  then
    while not neotest.lib.positions.contains(orig:data(), new:data()) do
      orig = wrap_with_parent(orig)
    end
  end

  local new_type = new:data().type
  if new_type ~= "dir" and new_type ~= "file" then
    error("Can't merge " .. new_type .. " into tree")
  end

  if new:data().type == "file" then
    update_file_node(orig, new, true)
    return orig
  end

  if neotest.lib.positions.contains(new:data(), orig:data()) then
    for _, node in orig:iter_nodes() do
      if node:data().type == "file" and new:get_key(node:data().id) then
        update_file_node(new, node)
      end
    end

    return new
  end

  local existing_dir = orig:get_key(new:data().id)
  if existing_dir then
    for _, node in existing_dir:iter_nodes() do
      if node:data().type == "file" and new:get_key(node:data().id) then
        update_file_node(new, node)
      end
    end
  end
  replace_node(orig, new)
  return orig
end

local function build_structure(positions, namespaces, opts)
  ---@type neotest.Position
  local parent = table.remove(positions, 1)
  if not parent then
    return nil
  end
  parent.id = parent.type == "file" and parent.path or opts.position_id(parent, namespaces)
  local current_level = { parent }
  local child_namespaces = vim.list_extend({}, namespaces)
  if parent.type == "namespace" or (opts.nested_tests and parent.type == "test") then
    child_namespaces[#child_namespaces + 1] = parent
  end
  if not parent.range then
    return current_level
  end
  while true do
    local next_pos = positions[1]
    if
      not next_pos or (next_pos.range and not neotest.lib.positions.contains(parent, next_pos))
    then
      -- Don't preserve empty namespaces
      if #current_level == 1 and parent.type == "namespace" then
        return nil
      end
      if opts.require_namespaces and parent.type == "test" and #namespaces == 0 then
        return nil
      end
      return current_level
    end

    local sub_tree = build_structure(positions, child_namespaces, opts)
    if opts.nested_tests or parent.type ~= "test" then
      current_level[#current_level + 1] = sub_tree
    end
  end
end

---@class neotest.lib.positions.ParseOptions
---@field nested_tests boolean Allow nested tests
---@field require_namespaces boolean Require tests to be within namespaces
---@field position_id fun(position: neotest.Position, parents: neotest.Position[]): string Position ID constructor

--- Convert a flat list of sorted positions to a tree. Positions ID fields can be nil as they will be assigned.
--- NOTE: This mutates the positions given by assigning the `id` field.
---@param positions neotest.Position[]
---@param opts neotest.lib.positions.ParseOptions
---@return neotest.Tree
function neotest.lib.positions.parse_tree(positions, opts)
  opts = vim.tbl_extend("force", {
    nested_tests = false, -- Allow nested tests
    require_namespaces = false, -- Only allow tests within namespaces
    ---@param position neotest.Position The position to return an ID for
    ---@param parents neotest.Position[] Parent positions for the position
    position_id = function(position, parents)
      return table.concat(
        utils.tbl_flatten({
          position.path,
          vim.tbl_map(function(pos)
            return pos.name
          end, parents),
          position.name,
        }),
        "::"
      )
    end,
  }, opts or {})
  local structure = assert(build_structure(positions, {}, opts))

  return Tree.from_list(structure, function(pos)
    return pos.id
  end)
end

return neotest.lib.positions
