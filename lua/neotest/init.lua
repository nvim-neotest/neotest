---@brief [[
---A NeoVim plugin to run tests and analyse results
---
---There are three main components to this plugin's architecture.
--- - Adapters: Generally language specific objects to parse tests, build commands and parse results
--- - Client: Runs tests and stores state of tests and results, emitting events during operation
--- - Consumers: Use the client to provide some utility to interact with tests and results
---
---In order to use neotest, you must use an adapter for your language of choice.
---You can supply them in the setup function.
---
---Once you have setup an adapter, you can use neotest module functions to run and interact with tests.
---
---For most users, the bulk of relevant features will be in the consumers.
---There are multiple consumers:
---
--- - summary: Shows all known tests in a tree structure, along with their current state.
---
--- - output: Displays the output of tests.
---
--- - diagnostics: Uses vim.diagnostic to show error messages where they occur (if supported by the adapter).
---
--- - status: Displays signs beside tests and namespaces to show current result state.
---
--- Each consumer can be accessed as a property of the neotest module
---
---<pre>
--->
---  require("neotest").summary.toggle()
---</pre>
---
---
---@brief ]]
local lib = require("neotest.lib")
local async = require("plenary.async")
local config = require("neotest.config")

---@tag neotest
local neotest = {}

---@type NeotestClient
local client
local consumers = {}

---Configure Neotest strategies and consumers
---<pre>
---    See: ~
---        |NeotestConfig|
---</pre>
---@param user_config NeotestConfig
---@eval { ['description'] = require('neotest.config')._format_default() }
function neotest.setup(user_config)
  config.setup(user_config)
  client = require("neotest.client")()
  for name, consumer in pairs(require("neotest.consumers")) do
    if config[name].enabled then
      consumers[name] = consumer(client)
    end
  end
end

local function get_tree_from_args(args)
  if args[1] then
    local position_id = lib.files.exists(args[1]) and async.fn.fnamemodify(args[1], ":p") or args[1]
    return client:get_position(position_id, { adapter = args.adapter })
  end
  local file_path = async.fn.expand("%:p")
  local row = async.fn.getpos(".")[2] - 1
  return client:get_nearest(file_path, row)
end

---Run the given position or the nearest position if not given.
---All arguments are optional
---
---Run the current file
---<pre>
--->
---lua require("neotest").run(vim.fn.expand("%"))
---</pre>
---
---Run the nearest test
---<pre>
--->
---lua require("neotest").run()
---</pre>
---
---Debug the current file with nvim-dap
---<pre>
--->
---lua require("neotest").run({vim.fn.expand("%"), strategy = "dap"})
---</pre>
---@param args string | table: Position ID to run or args. If args then args[1] should be the position ID.
---@field adapter string: Adapter ID, if not given the first adapter found with chosen position is used.
---@field strategy string: Strategy to run commands with
---@field extra_args string[]: Extra arguments for test command
function neotest.run(args)
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

---Stop a running process
---@param args string | table: Position ID to stop or args. If args then args[1] should be the position ID.
---@field adapter string: Adapter ID, if not given the first adapter found with chosen position is used.
function neotest.stop(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  async.run(function()
    local tree = get_tree_from_args(args)
    if not tree then
      lib.notify("No tests found", "warn")
      return
    end
    client:stop(tree, args)
  end)
end

---Attach to a running process for the given position.
---@param args string | table: Position ID to attach to or args. If args then args[1] should be the position ID.
---@field adapter string: Adapter ID, if not given the first adapter found with chosen position is used.
function neotest.attach(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  async.run(function()
    local pos = get_tree_from_args(args)
    if not pos then
      lib.notify("No tests found in file", "warn")
      return
    end
    client:attach(pos, args)
  end)
end

function neotest._update_positions(file_path)
  pcall(function()
    async.run(function()
      local adapter_id = client:get_adapter(file_path)
      if not client:get_position(file_path, { adapter = adapter_id }) then
        if not adapter_id then
          return
        end
        client:_update_positions(lib.files.parent(file_path), { adapter = adapter_id })
      end
      client:_update_positions(file_path, { adapter = adapter_id })
    end)
  end)
end

function neotest._update_files(path)
  async.run(function()
    client:_update_positions(path)
  end)
end

function neotest._dir_changed()
  async.run(function()
    client:_update_adapters(async.fn.getcwd())
  end)
end

function neotest._focus_file(path)
  async.run(function()
    client:_set_focused(path)
  end)
end

setmetatable(neotest, {
  __index = function(_, key)
    return consumers[key]
  end,
})

function neotest._P()
  for adapter, pos in pairs(client._state._positions) do
    PP({ [adapter] = pos })
  end
end

function neotest._C()
  for adapter, pos in pairs(client._state._positions) do
    local l = {
      test = 0,
      namespace = 0,
      file = 0,
      dir = 0,
    }
    for _, node in pairs(pos._nodes) do
      l[node:data().type] = l[node:data().type] + 1
    end
    P({ [adapter] = l })
  end
end

return neotest
