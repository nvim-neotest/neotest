local neotest = { lib = {} }

---@toc_entry Library: Function Utilities
---@text
--- Miscellaneous functions for working with functions.
--- Many of the functions have both a table and list variant.
---@class neotest.lib.func_util
neotest.lib.func_util = {}

--- Map over the values in a table
---@generic K, V
---@param f fun(k: any, v: any): K, V
---@param t table
---@return table<K, V>
function neotest.lib.func_util.map(f, t)
  local result = {}
  for k, v in pairs(t) do
    local new_k, new_v = f(k, v)
    result[new_k] = new_v
  end
  return result
end

--- Map over the values in a list
---@generic V
---@param f fun(i: integer, v: any): V
---@param t table
---@return V[]
function neotest.lib.func_util.map_list(f, t)
  local result = {}
  for i, v in ipairs(t) do
    local new_v = f(i, v)
    result[i] = new_v
  end
  return result
end

--- Filter elements from a table
---@generic K, V
---@param f fun(k: K, v: V): boolean
---@param t table<K, V>
---@return table<K, V>
function neotest.lib.func_util.filter(f, t)
  local new_t = {}
  for k, v in pairs(t) do
    if f(k, v) then
      new_t[k] = v
    end
  end
  return new_t
end

--- Filter elements from a list
---@generic V
---@param f fun(v: V): boolean
---@param t V[]
---@return V[]
function neotest.lib.func_util.filter_list(f, t)
  local new_t = {}
  for _, v in ipairs(t) do
    if f(v) then
      new_t[#new_t + 1] = v
    end
  end
  return new_t
end

--- Reverse a list, as an interator
---@generic E
---@param list E[]
---@return fun(): E
function neotest.lib.func_util.reverse(list)
  local i = #list + 1
  return function()
    i = i - 1
    if i <= 0 then
      return nil
    end
    return i, list[i]
  end
end

--- Search a list for an element
---@generic V
---@param list V[]
---@param item V
---@return integer | nil
function neotest.lib.func_util.index(list, item)
  for i, elem in ipairs(list) do
    if item == elem then
      return i
    end
  end
  return nil
end

--- Convert an iterator to a list
---@generic E
---@param iter fun(): E
---@return E[]
function neotest.lib.func_util.to_list(iter)
  local l = {}
  for val in iter do
    table.insert(val)
  end
  return l
end

--- Partially apply arguments to a function
---@param func function
---@param ... any Arguments to pass to func
---@return function
function neotest.lib.func_util.partial(func, ...)
  local args = { ... }
  return function(...)
    local final = vim.list_extend(args, { ... })
    return func(unpack(final))
  end
end

---@private
---@generic F
---@type fun(f: F): F
neotest.lib.func_util.memoize = require("neotest.lib.func_util.memoize")

return neotest.lib.func_util
