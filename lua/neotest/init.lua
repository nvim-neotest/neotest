local lib = require("neotest.lib")
local async = require("plenary.async")

vim.cmd([[
  hi default NeotestPassed ctermfg=Green guifg=#96F291
  hi default NeotestFailed ctermfg=Red guifg=#F70067
  hi default NeotestRunning ctermfg=Yellow guifg=#FFEC63
  hi default NeotestSkipped ctermfg=Cyan guifg=#00f1f5
  hi link NeotestTest Normal 
  hi default NeotestNamespace ctermfg=Magenta guifg=#D484FF
  hi default NeotestFile ctermfg=Cyan guifg=#00f1f5
  hi default NeotestDir ctermfg=Cyan guifg=#00f1f5
  hi default NeotestIndent ctermfg=Grey guifg=#8B8B8B
  hi default NeotestExpandMarker ctermfg=Grey guifg=#8094b4
]])

local M = {}

---@type NeotestClient
local client
local consumers = {}

function M.setup(config)
  local adapters = require("neotest.adapters")
  adapters.set_adapters(config.adapters or {})
  client = require("neotest.client")(adapters)
  for name, consumer in pairs(require("neotest.consumers")) do
    consumers[name] = consumer(client)
  end
end

local function get_tree_from_args(args)
  if args[1] then
    local position_id = lib.files.exists(args[1]) and async.fn.fnamemodify(args[1], ":p") or args[1]
    return client:get_position(position_id)
  end
  local file_path = async.fn.expand("%:p")
  local row = async.fn.getpos(".")[2] - 1
  return client:get_nearest(file_path, row)
end

function M.run(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  async.run(function()
    local tree = get_tree_from_args(args)
    if not tree then
      lib.notify("No tests found")
      return
    end
    client:run_tree(tree, args)
  end)
end

function M.stop(args)
  args = args or {}
  async.run(function()
    if type(args) == "string" then
      args = { args }
    end
    local tree = get_tree_from_args(args)
    if not tree then
      lib.notify("No tests found", "warn")
      return
    end
    client:stop(tree)
  end)
end

function M.attach(position_id)
  async.run(function()
    local pos
    if not position_id then
      local file_path = async.fn.expand("%:p")
      local row = async.fn.getpos(".")[2]
      pos = client:get_nearest(file_path, row)
    else
      pos = client:get_position(position_id)
    end
    if not pos then
      lib.notify("No tests found in file", "warn")
      return
    end
    client:attach(pos)
  end)
end

function M._update_positions(file_path)
  async.run(function()
    local c = client
    if not c:get_position(file_path, false) then
      if not c:is_test_file(file_path) then
        return
      end
      c:update_positions(lib.files.parent(file_path))
    end
    c:update_positions(file_path)
  end)
end

function M._update_files(path)
  async.run(function()
    client:update_positions(path)
  end)
end

setmetatable(M, {
  __index = function(self, key)
    return consumers[key]
  end,
})

function M._P()
  PP(client._state._positions)
end

function M._J(file)
  local file = io.open(file, "w")
  file:write(vim.json.encode(client._state._positions))
  file:close()
end

return M
