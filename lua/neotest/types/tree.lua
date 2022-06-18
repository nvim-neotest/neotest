local fu = require("neotest.lib.func_util")
---@class neotest.Tree
---@field private _data any
---@field private _children neotest.Tree[]
---@field private _nodes table<string, neotest.Tree>
---@field private _key fun(data: any): string
---@field private _parent? neotest.Tree
--- Nested tree structure with nodes containing data and having any
--- number of children
local Tree = {}

---@param data any Node data
---@param children neotest.Tree[] Children of this node
---@param key fun(data: any): string
---@param parent? neotest.Tree
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

---Parses a tree in the shape of nested lists.
---The head of the list is the root of the tree, and all following elements are its children.
---@param data any[]
---@return neotest.Tree
function Tree.from_list(data, key)
  local nodes = {}
  local x = Tree._from_list(data, key, nil, nodes)
  return x
end

function Tree:to_list()
  if #self._children == 0 then
    return { self._data }
  end
  local children = fu.map(function(i, t)
    return i, t:to_list()
  end, self._children)
  table.insert(children, 1, self._data)
  return children
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
---@param tree neotest.Tree
function Tree:add_child(key, tree)
  local current = self:get_key(key)
  if not current then
    tree._parent = self
    table.insert(self._children, tree)
  end
  self:set_key(key, tree)
end

---@parem key any
---@param tree neotest.Tree
function Tree:set_key(key, tree)
  local current = self:get_key(key)

  if current then
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
---@return neotest.Tree | nil
function Tree:get_key(key)
  return self._nodes[key]
end

---@return neotest.Position
function Tree:data()
  return self._data
end

---@return neotest.Tree[]
function Tree:children()
  return fu.map(function(i, pos_id)
    return i, pos_id
  end, self._children)
end

---@return neotest.Tree | nil
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

---@return neotest.Tree
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
