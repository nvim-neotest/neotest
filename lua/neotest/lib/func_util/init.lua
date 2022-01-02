local M = {}

---@generic K, V
---@param f fun(k: any, v: any): K, V
---@param t table
---@return table<K, V>
function M.map(f, t)
  local result = {}
  for k, v in pairs(t) do
    local new_k, new_v = f(k, v)
    result[new_k] = new_v
  end
  return result
end

---@generic K, V
---@param f fun(k: K, v: V): boolean
---@param t table
--@return table<K, V>
function M.filter(f, t)
  local new_t = {}
  for k, v in pairs(t) do
    if f(k, v) then
      new_t[k] = v
    end
  end
  return new_t
end

function M.filter_list(f, t)
  local new_l = {}
  for _, v in pairs(t) do
    if f(v) then
      new_l[#new_l + 1] = v
    end
  end
  return new_l
end

---@generic V
---@param list V[]
---@param item V
---@return integer | nil
function M.index(list, item)
  for i, elem in ipairs(list) do
    if item == elem then
      return i
    end
  end
  return nil
end

function M.to_list(iter)
  local l = {}
  for val in iter do
    table.insert(val)
  end
  return l
end

function M.partial(func, ...)
  local args = { ... }
  return function(...)
    local final = vim.list_extend(args, { ... })
    return func(unpack(final))
  end
end

---@generic F
---@type fun(f: F): F
M.memoize = require("neotest.lib.func_util.memoize")

return M
