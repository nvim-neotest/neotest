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
---Once you have setup an adapter, you can use neotest consumers to run and interact with tests.
---For most users, the bulk of relevant features will be in the consumers.
---There are multiple consumers:
--- - run: Allows running, debugging and stopping tests.
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
local config = require("neotest.config")

---@tag neotest
local neotest = {}

local consumers = {}

local consumer_client = function(client, name)
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
  local client = require("neotest.client")(adapter_group)
  local all_consumers = vim.tbl_extend("error", require("neotest.consumers"), config.consumers)
  for name, consumer in pairs(all_consumers) do
    if not config[name] or config[name].enabled then
      consumers[name] = consumer(consumer_client(client, name)) or {}
    end
  end
end

setmetatable(neotest, {
  __index = function(_, key)
    return consumers[key]
  end,
})

return neotest
