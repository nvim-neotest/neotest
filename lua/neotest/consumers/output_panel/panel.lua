local config = require("neotest.config")
local lib = require("neotest.lib")

---@class neotest.OutputPanel
---@field client neotest.Client
---@field win neotest.PersistentWindow
---@private
local OutputPanel = {}

function OutputPanel:new(client)
  self.__index = self
  return setmetatable({
    client = client,
    win = lib.persistent_window.panel({
      name = "Neotest Output Panel",
      open = config.output_panel.open,
      bufopts = {
        filetype = "neotest-output-panel",
      },
    }),
  }, self)
end

return function(client)
  return OutputPanel:new(client)
end
