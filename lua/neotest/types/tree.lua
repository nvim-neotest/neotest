local fu = require("neotest.lib.func_util")
---@class Tree
---@field private _data any
---@field private _children string[]
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
  }
  tree._nodes[key(data)] = tree
  setmetatable(tree, self)
  self.__index = self
  tree:_update_children(children)
  return tree
end

function Tree:_update_children(children)
  self._children = children
end

---@return integer
function Tree:length()
  local length = 1
  for _, child in pairs(self._children) do
    length = length + self._nodes[child]:length()
  end
  return length
end

--- Parses a tree in the shape of nested lists.
--- The head of the list is the root of the tree, and all following elements are its children.
---@parm data any[]
function Tree.from_list(data, key)
  local nodes = {}
  local node_key = Tree._from_list(data, key, nil, nodes)
  return nodes[node_key]
end

function Tree._from_list(data, key, parent, nodes)
  local node_key
  local node
  if vim.tbl_islist(data) then
    local node_data = data[1]
    node_key = key(node_data)
    node = Tree:new(node_data, {}, key, parent, nodes)
    local children = {}
    for i = 2, #data, 1 do
      children[#children + 1] = Tree._from_list(data[i], key, node_key, nodes)
    end
    node:_update_children(children)
  else
    node_key = key(data)
    node = Tree:new(data, {}, key, parent, nodes)
  end
  nodes[node_key] = node
  return node_key
end

---@param index integer
---@return any | nil
function Tree:get(index)
  if index > self:length() then
    return nil
  end

  if index == 0 then
    return self._data
  end

  local checked = 1
  for _, child in pairs(self:children()) do
    if child:length() > index - checked then
      return child:get(index - checked)
    end
    checked = checked + child:length()
  end

  return nil
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
      if key == child then
        parent._children[i] = key
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
    return i, self._nodes[pos_id]
  end, self._children)
end

---@return Tree | nil
function Tree:parent()
  return self._parent and self._nodes[self._parent]
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
        child_iter = self._nodes[self._children[child_i]]:iter_nodes()
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

-----Binary search through sorted tree
-----@param target any Value given from key function
-----@param key fun(data: any): any Function to apply to node data to give comparable value
-----@param strict boolean Only return node if exact match, else give closest
-----@return Tree | nil
--function Tree:sorted_search(target, key, strict)
--  local l, r = 1, self:length()
--  while l <= r do
--    local m = math.floor((l + r) / 2)
--    local mid = self:node(m)
--    local search_key_value = key(mid:data())

--    if search_key_value < target then
--      l = m + 1
--    elseif search_key_value > target then
--      r = m - 1
--    else
--      return mid
--    end
--  end
--  if r <= 0 then
--    return nil
--  end
--  local closest = self:node(r)
--  if strict or key(closest:data()) >= target then
--    return nil
--  end
--  return closest
--end

-----Linear search through tree
-----@param target any Value given from key function
-----@param key fun(data: any): any Function to apply to node data to give comparable value
--function Tree:search(target, key)
--  for node in self:iter_nodes() do
--    if key(node:data()) == target then
--      return node
--    end
--  end
--end

return Tree
