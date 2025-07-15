local lib = require("neotest.lib")
local nio = require("nio")
local OutputPanel = require("neotest.consumers.output_panel.panel")

---@private
---@type neotest.OutputPanel
local panel

local neotest = {}

---@toc_entry Output Panel Consumer
---@text
--- A consumer that streams all output of tests to a terminal window.
---@class neotest.consumers.output_panel
neotest.output_panel = {}

---@param client neotest.Client
---@private
local init = function(client)
  panel = OutputPanel(client)

  local chan
  ---@param results table<string, neotest.Result>
  client.listeners.results = function(adapter_id, results, partial)
    if partial then
      return
    end

    local channel_is_valid = function(chan_id)
      return chan_id and pcall(vim.api.nvim_chan_send, chan_id, "\n")
    end

    if not channel_is_valid(chan) then
      chan = lib.ui.open_term(panel.win:buffer())
      -- neovim sometimes adds random blank lines when creating a terminal buffer
      nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", true)
      nio.api.nvim_buf_set_lines(panel.win:buffer(), 0, -1, false, {})
      nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", false)
    end
    local files_to_read = {}

    local tree = client:get_position(nil, { adapter = adapter_id })
    assert(tree, "No tree for adapter " .. adapter_id)
    for pos_id, result in pairs(results) do
      if
        result.output
        and not files_to_read[result.output]
        and tree:get_key(pos_id)
        and tree:get_key(pos_id):data().type == "test"
      then
        files_to_read[result.output] = true
      end
    end

    for file, _ in pairs(files_to_read) do
      local output = lib.files.read(file)
      local dos_newlines = string.find(output, "\r\n") ~= nil
      if
        not pcall(
          nio.api.nvim_chan_send,
          chan,
          dos_newlines and output or output:gsub("\n", "\r\n")
        )
      then
        lib.notify(("Error sending output to term channel: %s"):format(chan), vim.log.levels.ERROR)
        chan = nil
        break
      end
    end
  end
end

--- Open the output panel
--- ```vim
---   lua require("neotest").output_panel.open()
--- ```
function neotest.output_panel.open()
  panel.win:open()
end

--- Close the output panel
--- ```vim
---   lua require("neotest").output_panel.close()
--- ```
function neotest.output_panel.close()
  panel.win:close()
end

--- Toggle the output panel
--- ```vim
---   lua require("neotest").output_panel.toggle()
--- ```
function neotest.output_panel.toggle()
  if panel.win:is_open() then
    neotest.output_panel.close()
  else
    neotest.output_panel.open()
  end
end

--- Clears the output panel
--- >vim
---   lua require("neotest").output_panel.clear()
--- <
function neotest.output_panel.clear()
  nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", true)
  nio.api.nvim_buf_set_lines(panel.win:buffer(), 0, -1, false, {})
  nio.api.nvim_buf_set_option(panel.win:buffer(), "modifiable", false)
end

--- Returns the buffer of the output panel
--- ```vim
---   lua require("neotest").output_panel.buffer()
--- ```
function neotest.output_panel.buffer()
  return panel.win:buffer()
end

neotest.output_panel = setmetatable(neotest.output_panel, {
  __call = function(_, client)
    init(client)
    return neotest.output_panel
  end,
})

return neotest.output_panel
