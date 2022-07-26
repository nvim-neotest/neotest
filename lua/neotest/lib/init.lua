local xml = require("neotest.lib.xml")
local xml_tree = require("neotest.lib.xml.tree")

local M = {}

M.xml = {
  ---@param xml_data string
  ---@return table
  parse = function(xml_data)
    local handler = xml_tree:new()
    local parser = xml.parser(handler)
    parser:parse(xml_data)
    return handler.root
  end,
}

M.files = require("neotest.lib.file")

M.func_util = require("neotest.lib.func_util")

M.treesitter = require("neotest.lib.treesitter")

M.notify = function(msg, level, opts)
  vim.schedule(function()
    return vim.notify(
      msg,
      level,
      vim.tbl_extend("keep", opts or {}, {
        title = "Neotest",
        icon = "ﭧ",
      })
    )
  end)
end

M.vim_test = require("neotest.lib.vim_test")

M.ui = require("neotest.lib.ui")

M.positions = require("neotest.lib.positions")

M.process = require("neotest.lib.process")

return M
