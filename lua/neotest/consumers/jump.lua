local nio = require("nio")
local lib = require("neotest.lib")

---@private
---@type neotest.Client
local client

local neotest = {}

---@toc_entry Jump Consumer
---@text
--- A consumer that allows jumping between tests
---
--- Example mappings to jump between test failures
--- ```vim
---   nnoremap <silent>[n <cmd>lua require("neotest").jump.prev({ status = "failed" })<CR>
---   nnoremap <silent>]n <cmd>lua require("neotest").jump.next({ status = "failed" })<CR>
--- ```
---@class neotest.consumers.jump
neotest.jump = {}

local get_nearest = function()
  local path = nio.fn.expand("%:p")
  local cur_pos = nio.api.nvim_win_get_cursor(0)
  local pos, adapter_id = client:get_nearest(path, cur_pos[1] - 1)
  if not pos then
    lib.notify("Couldn't find any tests in file", vim.log.levels.WARN)
    return
  end
  return pos, adapter_id
end

local function jump_to(node)
  local range = node:closest_value_for("range")
  nio.api.nvim_win_set_cursor(0, { range[1] + 1, range[2] })
end

local function match_status(status, adapter_id)
  return function(node)
    local result = client:get_results(adapter_id)[node:data().id]
    return result and result.status == status
  end
end

---@param pos neotest.Tree
---@private
local jump_to_prev = function(pos, predicate)
  if pos:data().type == "file" then
    return false
  end
  if nio.api.nvim_win_get_cursor(0)[1] - 1 > pos:closest_value_for("range")[1] then
    jump_to(pos)
    return true
  end
  local file_pos = pos:get_key(pos:data().path)
  assert(file_pos)

  local last_found
  for _, child in file_pos:iter_nodes() do
    if last_found then
      if child:data().id == pos:data().id and last_found:data().type ~= "file" then
        jump_to(last_found)
        return true
      end
    end
    if predicate(child) then
      last_found = child
    end
  end
end

---@param pos neotest.Tree
---@private
local jump_to_next = function(pos, predicate)
  local file_pos = pos:get_key(pos:data().path)
  assert(file_pos)

  local pos_found = false
  for _, child in file_pos:iter_nodes() do
    if pos_found and predicate(child) then
      jump_to(child)
      return true
    end
    pos_found = pos_found or child:data().id == pos:data().id
  end
end

---@class neotest.jump.JumpArgs
---@field status string Only jump to positions with given status

--- Jump to the position after the cursor position in the current file
---@param args? neotest.jump.JumpArgs
function neotest.jump.next(args)
  args = args or {}

  nio.run(function()
    local pos, adapter_id = get_nearest()
    if not pos then
      return
    end
    local predicate = args.status and match_status(args.status, adapter_id)
      or function()
        return true
      end

    if not jump_to_next(pos, predicate) then
      lib.notify("No tests below cursor", vim.log.levels.WARN)
    end
  end)
end

---Jump to the position after the cursor position in the current file
---@param args? neotest.jump.JumpArgs
function neotest.jump.prev(args)
  args = args or {}
  nio.run(function()
    local pos, adapter_id = get_nearest()
    if not pos then
      return
    end
    local predicate = args.status and match_status(args.status, adapter_id)
      or function()
        return true
      end

    if not jump_to_prev(pos, predicate) then
      lib.notify("No tests above cursor", vim.log.levels.WARN)
    end
  end)
end

neotest.jump = setmetatable(neotest.jump, {
  __call = function(_, client_)
    client = client_
    return neotest.jump
  end,
})

return neotest.jump
