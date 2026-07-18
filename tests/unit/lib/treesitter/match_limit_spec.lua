local nio = require("nio")
local a = nio.tests
local lib = require("neotest.lib")

describe("lib.treesitter.parse_positions_from_string with match_limit", function()
  local file_path = "/match_limit_test.lua"
  -- Binding every function to the single trailing return_statement keeps each
  -- match in progress until the end of the chunk, so the query cursor's
  -- match buffer fills up and evicts the earliest-starting matches once its
  -- limit is exceeded.
  local query = [[
(chunk
  (function_declaration name: (identifier) @test.name) @test.definition
  (return_statement))
]]

  local function build_test_content()
    local lines = {}
    for i = 1, 400 do
      local name = string.format("test_%03d", i)
      table.insert(lines, string.format("local function %s() end", name))
    end
    table.insert(lines, "return true")
    return table.concat(lines, "\n")
  end

  local function collect_test_names(tree)
    local names = {}
    for _, pos in tree:iter() do
      if pos.type == "test" then
        table.insert(names, pos.name)
      end
    end
    return names
  end

  a.it("detects all positions when match_limit is raised", function()
    local content = build_test_content()
    local opts = { match_limit = 1024 }

    local tree = lib.treesitter.parse_positions_from_string(file_path, content, query, opts)
    local names = collect_test_names(tree)

    assert.are.equal(400, #names)
    assert.are.equal("test_001", names[1])
    assert.are.equal("test_400", names[#names])
  end)

  a.it("forwards match_limit to the query cursor", function()
    local content = build_test_content()
    local opts = { match_limit = 8 }

    local tree = lib.treesitter.parse_positions_from_string(file_path, content, query, opts)
    local names = collect_test_names(tree)

    assert.is_true(#names < 400)
    assert.are.equal("test_400", names[#names])
    assert.is_not.equal("test_001", names[1])
  end)
end)
