local fu = require("neotest.lib.func_util")

local neotest = {}

--- Nested tree structure with nodes containing data and having any
--- number of children
---@class neotest.Tree
---@field private _data any
---@field private _children neotest.Tree[]
---@field private _nodes table<string, neotest.Tree>
---@field private _key fun(data: any): string
---@field private _parent? neotest.Tree
neotest.Tree = {}

---@param data any Node data
---@param children neotest.Tree[] Children of this node
---@param key fun(data: any): string
---@param parent? neotest.Tree
---@private
function neotest.Tree:new(data, children, key, parent, nodes)
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

--- Parses a tree in the shape of nested lists.
--- The head of the list is the root of the tree, and all following elements are its children.
---@param data any[]
---@return neotest.Tree
function neotest.Tree.from_list(data, key)
  local nodes = {}
  local x = neotest.Tree._from_list(data, key, nil, nodes)
  return x
end

---@private
function neotest.Tree:__tostring()
  return vim.inspect(self:to_list())
end

--- Returns the tree as a nested list which can be parsed by the `from_list`
--- method
---@return any[]
function neotest.Tree:to_list()
  if #self._children == 0 then
    return { self._data }
  end
  local children = fu.map(function(i, t)
    return i, t:to_list()
  end, self._children)
  table.insert(children, 1, self._data)
  return children
end

---@private
function neotest.Tree._from_list(data, key, parent, nodes)
  local node_key
  local node
  if (vim.islist or vim.tbl_islist)(data) then
    local node_data = data[1]
    node_key = key(node_data)
    local children = {}
    node = neotest.Tree:new(node_data, children, key, parent, nodes)
    for i = 2, #data, 1 do
      children[#children + 1] = neotest.Tree._from_list(data[i], key, node, nodes)
    end
  else
    node_key = key(data)
    node = neotest.Tree:new(data, {}, key, parent, nodes)
  end
  nodes[node_key] = node
  return node
end

---@parem key any
---@param tree neotest.Tree
---@private
function neotest.Tree:add_child(key, tree)
  local current = self:get_key(key)
  if not current then
    tree._parent = self
    table.insert(self._children, tree)
  end
  self:set_key(key, tree)
end

---@parem key any
---@param tree neotest.Tree
---@private
function neotest.Tree:set_key(key, tree)
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
function neotest.Tree:get_key(key)
  return self._nodes[key]
end

---@return neotest.Position
function neotest.Tree:data()
  return self._data
end

---@return neotest.Tree[]
function neotest.Tree:children()
  return fu.map(function(i, pos_id)
    return i, pos_id
  end, self._children)
end

---@return neotest.Tree | nil
function neotest.Tree:parent()
  return self._parent
end

---@return fun(): neotest.Tree
function neotest.Tree:iter_parents()
  local parent = self:parent()
  return function()
    local cur_node = parent
    if cur_node then
      parent = cur_node:parent()
    end
    return cur_node
  end
end

--- Fetch the first node ascending the tree (including the current one) with the
--- given data attribute e.g. `range`
---@param data_attr string
---@return neotest.Tree | nil
function neotest.Tree:closest_node_with(data_attr)
  if self:data()[data_attr] ~= nil then
    return self
  end
  for parent in self:iter_parents() do
    if parent:data()[data_attr] ~= nil then
      return parent
    end
  end
end

--- Fetch the first non-nil value for the given data attribute ascending the
--- tree (including the current node) with the given data attribute.
---@param data_attr string
---@return any | nil
function neotest.Tree:closest_value_for(data_attr)
  local nearest = self:closest_node_with(data_attr)
  return nearest and nearest:data()[data_attr]
end

---@return neotest.Tree
function neotest.Tree:root()
  local node = self
  while node:parent() do
    node = node:parent()
  end
  return node
end

---@class neotest.types.tree.IterNodesArgs
---@field continue fun(node: neotest.Tree): boolean A predicate for if the given node's children should be iterated over.  Defaults to `true`.

---@param args? neotest.types.tree.IterNodesArgs
---@return fun():integer,neotest.Tree
function neotest.Tree:iter_nodes(args)
  args = args or {}
  local child_i = 0
  local total_i = 1
  local child_iter = nil
  local continue = not args.continue and true or args.continue(self)
  return function()
    if child_i == 0 then
      child_i = 1
      return 1, self
    end
    if not continue then
      return nil
    end

    while true do
      if not child_iter then
        if #self._children < child_i then
          return nil
        end
        child_iter = self._children[child_i]:iter_nodes(args)
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

---@param args? neotest.types.tree.IterNodesArgs
---@return fun():integer,neotest.Position
function neotest.Tree:iter(args)
  local node_iter = self:iter_nodes(args)
  return function()
    local i, node = node_iter()
    if not i then
      return nil
    end
    return i, node:data()
  end
end

---@param index integer
function neotest.Tree:node(index)
  for i, node in self:iter_nodes() do
    if i == index then
      return node
    end
  end
end

return neotest.Tree
