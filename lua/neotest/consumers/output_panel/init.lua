local lib = require("neotest.lib")
local async = require("neotest.async")
local OutputPanel = require("neotest.consumers.output_panel.panel")

---@private
---@type neotest.OutputPanel
local panel

local neotest = {}

---@toc_entry Output Panel Consumer
---@text
--- A consumer that streams all output of tests to a terminal window.
neotest.output_panel = {}

---@param client neotest.Client
local init = function(client)
  panel = OutputPanel(client)

  local chan
  ---@param results table<string, neotest.Result>
  client.listeners.results = function(_, results, partial)
    if partial then
      return
    end
    if not chan then
      chan = lib.ui.open_term(panel.win:buffer())
      -- neovim sometimes adds random blank lines when creating a terminal buffer
      async.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", true)
      async.api.nvim_buf_set_lines(panel.win:buffer(), 0, -1, false, {})
      async.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", false)
    end
    local files_read = {}

    for _, result in pairs(results) do
      if result.output and not files_read[result.output] then
        files_read[result.output] = true
      end
    end

    for file, _ in pairs(files_read) do
      async.api.nvim_chan_send(chan, lib.files.read(file))
    end
  end
end

--- Open the output panel
--- >
---   lua require("neotest").output_panel.open()
--- <
function neotest.output_panel.open()
  panel.win:open()
end

--- Close the output panel
--- >
---   lua require("neotest").output_panel.close()
--- <
function neotest.output_panel.close()
  panel.win:close()
end

--- Toggle the output panel
--- >
---   lua require("neotest").output_panel.toggle()
--- <
function neotest.output_panel.toggle()
  if panel.win:is_open() then
    neotest.output_panel.close()
  else
    neotest.output_panel.open()
  end
end

neotest.output_panel = setmetatable(neotest.output_panel, {
  __call = function(_, client)
    init(client)
    return neotest.output_panel
  end,
})

return neotest.output_panel
