local M = {}

local function get_scope(position)
  if not position or position.type == "dir" then
    return "suite"
  end
  if position.type == "file" then
    return "file"
  end
  return "nearest"
end

---@param lang string
---@param runner string
---@param position? neotest.Position
function M.collect_args(lang, runner, position)
  local opts = vim.g["test#" .. lang .. "#" .. runner .. "#options"]
  if type(opts) == "string" then
    return vim.split(opts, " ")
  end
  if type(opts) == "table" then
    local scope = get_scope(position)
    local args = {}
    if opts[scope] then
      vim.list_extend(args, opts[scope])
    end
    if opts.all then
      vim.list_extend(args, opts.all)
    end
    return args
  end
end

return M
