local docgen = require("docgen")

local docs = {}

docs.test = function()
  local input_files = {
    "./lua/neotest/init.lua",
    "./lua/neotest/config/init.lua",
    "./lua/neotest/consumers/init.lua",
    "./lua/neotest/consumers/output.lua",
    "./lua/neotest/consumers/run.lua",
    "./lua/neotest/consumers/status.lua",
    "./lua/neotest/consumers/diagnostic.lua",
    "./lua/neotest/consumers/summary/init.lua",
    "./lua/neotest/consumers/jump.lua",
  }

  -- Output file
  local output_file = "./doc/neotest.txt"
  local output_file_handle = io.open(output_file, "w")

  for _, input_file in ipairs(input_files) do
    docgen.write(input_file, output_file_handle)
  end

  output_file_handle:write(" vim:tw=78:ts=8:ft=help:norl:\n")
  output_file_handle:close()
  vim.cmd([[checktime]])
end

docs.test()

return docs
