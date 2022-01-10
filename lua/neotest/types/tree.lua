local fu = require("neotest.lib.func_util")
---@class Tree
---@field private _data any
---@field private _children Tree[]
---@field private _nodes table<string, Tree>
---@field private _key fun(data: any): string
---@field private _parent? Tree
--- Nested tree structure with nodes containing data and having any
--- number of children
local Tree = {}

---@param data any Node data
---@param children Tree[] Children of this node
---@param key fun(data: any): string
---@param parent? Tree
function Tree:new(data, children, key, parent, nodes)
  local tree = {
    _nodes = nodes or {},
    _data = data,
    _key = key,
    _parent = parent,
    _children = children,
  }
  tree._nodes[key(data)] = tree
  setmetatable(tree, self)
  self.__index = self
  return tree
end

---@return integer
function Tree:length()
  local length = 1
  for _, child in ipairs(self:children()) do
    length = length + child:length()
  end
  return length
end

---Parses a tree in the shape of nested lists.
---The head of the list is the root of the tree, and all following elements are its children.
---@param data any[]
---@return Tree
function Tree.from_list(data, key)
  local nodes = {}
  local x = Tree._from_list(data, key, nil, nodes)
  return x
end

function Tree._from_list(data, key, parent, nodes)
  local node_key
  local node
  if vim.tbl_islist(data) then
    local node_data = data[1]
    node_key = key(node_data)
    local children = {}
    node = Tree:new(node_data, children, key, parent, nodes)
    for i = 2, #data, 1 do
      children[#children + 1] = Tree._from_list(data[i], key, node, nodes)
    end
  else
    node_key = key(data)
    node = Tree:new(data, {}, key, parent, nodes)
  end
  nodes[node_key] = node
  return node
end

---@parem key any
---@param tree Tree
function Tree:set_key(key, tree)
  local current = self:get_key(key)

  -- Remove dandling children
  local to_remove = {}
  for _, node in current:iter() do
    table.insert(to_remove, self._key(node))
  end
  for _, node_key in pairs(to_remove) do
    self._nodes[node_key] = nil
  end

  self._nodes[key] = tree

  -- Replace child key in parent
  local parent = current:parent()
  if parent then
    tree._parent = current._parent
    for i, child in pairs(parent._children) do
      if key == self._key(child:data()) then
        parent._children[i] = tree
        break
      end
    end
  end

  -- Combine the tree nodes
  for node_key, node in pairs(tree._nodes) do
    self._nodes[node_key] = node
  end
  for _, node in pairs(tree._nodes) do
    node._nodes = self._nodes
  end
end

---@param key any
---@return Tree | nil
function Tree:get_key(key)
  return self._nodes[key]
end

---@return NeotestPosition
function Tree:data()
  return self._data
end

---@return Tree[]
function Tree:children()
  return fu.map(function(i, pos_id)
    return i, pos_id
  end, self._children)
end

---@return Tree | nil
function Tree:parent()
  return self._parent
end

function Tree:iter_parents()
  local parent = self:parent()
  return function()
    local cur_node = parent
    if cur_node then
      parent = cur_node:parent()
    end
    return cur_node
  end
end

---@return Tree
function Tree:root()
  local node = self
  while node:parent() do
    node = node:parent()
  end
  return node
end

function Tree:iter_nodes()
  local child_i = 0
  local total_i = 1
  local child_iter = nil
  return function()
    if child_i == 0 then
      child_i = 1
      return 1, self
    end

    while true do
      if not child_iter then
        if #self._children < child_i then
          return nil
        end
        child_iter = self._children[child_i]:iter_nodes()
      end
      local _, child_data = child_iter()
      if child_data then
        total_i = total_i + 1
        return total_i, child_data
      end
      child_i = child_i + 1
      child_iter = nil
    end
  end
end

function Tree:iter()
  local node_iter = self:iter_nodes()
  return function()
    local i, node = node_iter()
    if not i then
      return nil
    end
    return i, node:data()
  end
end

---@param index integer
function Tree:node(index)
  for i, node in self:iter_nodes() do
    if i == index then
      return node
    end
  end
end

return Tree
