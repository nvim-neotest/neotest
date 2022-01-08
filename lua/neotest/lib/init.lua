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
  return vim.notify(
    msg,
    level,
    vim.tbl_extend("keep", opts or {}, {
      title = "Neotest",
      icon = "ﭧ",
    })
  )
end

M.vim_test = require("neotest.lib.vim_test")

M.ui = require("neotest.lib.ui")

M.positions = {
  ---@param tree Tree
  ---@param line integer
  ---@return Tree
  nearest = function(tree, line)
    local nearest = tree
    for _, node in tree:iter_nodes() do
      local pos = node:data()
      if pos.range then
        if line >= pos.range[1] then
          nearest = node
        else
          return nearest
        end
      end
    end
    return nearest
  end,
  ---@param parent NeotestPosition
  ---@param child NeotestPosition
  ---@return boolean
  contains = function(parent, child)
    if parent.type == "dir" then
      return parent.path == child.path or vim.startswith(child.path, parent.path .. M.files.sep)
    end
    if child.type == "dir" then
      return false
    end
    return parent.range[1] <= child.range[1] and parent.range[3] >= child.range[3]
  end,
}

return M
