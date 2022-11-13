local M = {}

local lazy_require = require("neotest.lib.require")

local xml = lazy_require("neotest.lib.xml")
local xml_tree = lazy_require("neotest.lib.xml.tree")

M.xml = {
  ---@param xml_data string
  ---@return table
  parse = function(xml_data)
    local handler = xml_tree()
    local parser = xml.parser(handler)
    parser:parse(xml_data)
    return handler.root
  end,
}

---@module 'neotest.lib.file'
M.files = lazy_require("neotest.lib.file")

---@module 'neotest.lib.func_util'
M.func_util = lazy_require("neotest.lib.func_util")

---@module 'neotest.lib.treesitter''
M.treesitter = lazy_require("neotest.lib.treesitter")

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

---@module 'neotest.lib.window''
M.persistent_window = lazy_require("neotest.lib.window")

---@module 'neotest.lib.vim_test''
M.vim_test = lazy_require("neotest.lib.vim_test")

---@module 'neotest.lib.ui''
M.ui = lazy_require("neotest.lib.ui")

---@module 'neotest.lib.positions''
M.positions = lazy_require("neotest.lib.positions")

---@module 'neotest.lib.process''
M.process = lazy_require("neotest.lib.process")

---Module to interact with a child Neovim instance.
---This can be used for CPU intensive work like treesitter parsing.
---All usage should be guarded by checking that the subprocess has been started using the `enabled` function.
---@module 'neotest.lib.subprocess''
M.subprocess = lazy_require("neotest.lib.subprocess")

return M
