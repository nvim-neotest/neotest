---@brief [[
---A framework to interact with tests within NeoVim.
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
local async = require("neotest.async")
local config = require("neotest.config")

---@tag neotest
local neotest = {}

---@type neotest.InternalClient
local client
local consumers = {}

local consumer_client = function(name)
  local consumer_listeners = {}

  setmetatable(consumer_listeners, {
    __index = function()
      error("Cannot access existing listeners")
    end,
    __newindex = function(_, key, value)
      if not client.listeners[key] then
        error("Invalid event name for client: " .. key)
      end
      client.listeners[key][name] = value
    end,
  })

  local consumer_client = { listeners = consumer_listeners }
  setmetatable(consumer_client, {
    __index = function(_, key)
      local value = client[key]
      if type(value) ~= "function" then
        return value
      end
      return function(maybe_client, ...)
        if maybe_client == consumer_client then
          return value(client, ...)
        end
        return value(...)
      end
    end,
  })
  return consumer_client
end

---Configure Neotest strategies and consumers
---<pre>
---    See: ~
---        |neotest.Config|
---</pre>
---@param user_config neotest.Config
---@eval { ['description'] = require('neotest.config')._format_default() }
function neotest.setup(user_config)
  config.setup(user_config)
  local adapter_group = require("neotest.adapters")(config.adapters)
  client = require("neotest.client")(adapter_group)
  for name, consumer in pairs(require("neotest.consumers")) do
    if config[name].enabled then
      consumers[name] = consumer(consumer_client(name))
    end
  end
end

local function get_tree_from_args(args)
  if args[1] then
    local position_id = lib.files.exists(args[1]) and async.fn.fnamemodify(args[1], ":p") or args[1]
    return client:get_position(position_id, args)
  end
  local file_path = async.fn.expand("%:p")
  local row = async.fn.getpos(".")[2] - 1
  return client:get_nearest(file_path, row, args)
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
---@field strategy string | neotest.Strategy: Strategy to run commands with
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

setmetatable(neotest, {
  __index = function(_, key)
    return consumers[key]
  end,
})

return neotest
