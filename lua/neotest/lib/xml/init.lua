local xml2lua = require("neotest.lib.xml.internal")
local xml_tree = require("neotest.lib.xml.tree")

local neotest = { lib = {} }

---@toc_entry Library: XML
---@text
--- Library to parse XML strings.
--- Originially taken from https://github.com/manoelcampos/xml2lua
---@class neotest.lib.xml
neotest.lib.xml = {}

---@param xml_data string
---@return table
function neotest.lib.xml.parse(xml_data)
  local handler = xml_tree()
  local parser = xml2lua.parser(handler)
  parser:parse(xml_data)
  return handler.root
end

return neotest.lib.xml
