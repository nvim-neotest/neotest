local neotest = {}

---@toc_entry Consumers
---@text
--- Consumers provide user consumable APIs by wrapping the lower level client
--- object. If you are developing a consumer, it is strongly recommended to enable
--- type checking of the `neotest` repo, as it will provide very helpful type
--- hints/docs. You can use https://github.com/folke/lua-dev.nvim to do this easily.
---
--- A consumer is a function which takes a neotest.Client object. The function can
--- optionally return a table containing functions which will be directly accessable
--- on the `neotest` module under the consumers name. For example, the `run`
--- consumer returns a table with `run`, `attach` and `stop` and so users can call
--- `neotest.run.run`, `neotest.run.attach` and `neotest.run.stop`
---
--- The client interface provides methods for interacting with tests, fetching
--- results as well as event listeners. To listen to an event, just assign the event
--- listener to a function:
--- ```lua
---   client.listeners.discover_positions = function (adapter_id, tree)
---     ...
---   end
--- ```
--- Available events and the listener signatures are visible as properties on the
--- `client.listeners` table
---
--- The majority of interactions with the client will involved the use of the
--- positions tree. Each adapter instance has a separate tree, so you should track
--- which adapter ID you are using throughout several calls.
neotest.consumers = {
  run = require("neotest.consumers.run"),
  diagnostic = require("neotest.consumers.diagnostic"),
  status = require("neotest.consumers.status"),
  output = require("neotest.consumers.output"),
  output_panel = require("neotest.consumers.output_panel"),
  summary = require("neotest.consumers.summary"),
  jump = require("neotest.consumers.jump"),
  benchmark = require("neotest.consumers.benchmark"),
  quickfix = require("neotest.consumers.quickfix"),
  state = require("neotest.consumers.state"),
  watch = require("neotest.consumers.watch"),
}

return neotest.consumers
