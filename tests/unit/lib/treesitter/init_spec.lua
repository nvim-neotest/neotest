local async = require("neotest.async")
local a = async.tests
local lib = require("neotest.lib")
local ts = lib.treesitter

local plenary_queries = [[
  ;; describe blocks
  ((function_call
      name: (identifier) @func_name (#match? @func_name "^describe$")
      arguments: (arguments (_) @namespace.name (function_definition))
  )) @namespace.definition


  ;; it blocks
  ((function_call
      name: (identifier) @func_name
      arguments: (arguments (_) @test.name (function_definition))
  ) (#match? @func_name "^it$")) @test.definition

  ;; async it blocks (async.it)
  ((function_call
      name: (
        dot_index_expression 
          field: (identifier) @func_name
      )
      arguments: (arguments (_) @test.name (function_definition))
    ) (#match? @func_name "^it$")) @test.definition
    ]]

local test_file = [[
describe("top namespace", function()
  it("test 1", function()
  end)

  it("test 2", function()
    it("nested test", function()
    end)
  end)
end)

it("test 3", function()
end)
]]

local function tree_to_list(iter)
  local l = {}

  for _, elem in iter do
    l[#l + 1] = elem
  end
  return l
end

describe("treesitter parsing", function()
  a.it("finds all positions", function()
    local tree = ts.parse_positions_from_string("test_spec.lua", test_file, plenary_queries, {})
    local result = tree:to_list()
    assert.are.same({
      {
        id = "test_spec.lua",
        name = "test_spec.lua",
        path = "test_spec.lua",
        range = { 0, 0, 12, 0 },
        type = "file",
      },
      {
        {
          id = 'test_spec.lua::"top namespace"',
          name = '"top namespace"',
          path = "test_spec.lua",
          range = { 0, 0, 8, 4 },
          type = "namespace",
        },
        {
          {
            id = 'test_spec.lua::"top namespace"::"test 1"',
            name = '"test 1"',
            path = "test_spec.lua",
            range = { 1, 2, 2, 6 },
            type = "test",
          },
        },
        {
          {
            id = 'test_spec.lua::"top namespace"::"test 2"',
            name = '"test 2"',
            path = "test_spec.lua",
            range = { 4, 2, 7, 6 },
            type = "test",
          },
        },
      },
      {
        {
          id = 'test_spec.lua::"test 3"',
          name = '"test 3"',
          path = "test_spec.lua",
          range = { 10, 0, 11, 4 },
          type = "test",
        },
      },
    }, result)
  end)
  a.it("finds all positions with nested tests", function()
    local tree = ts.parse_positions_from_string(
      "test_spec.lua",
      test_file,
      plenary_queries,
      { nested_tests = true }
    )
    assert.are.same({
      id = 'test_spec.lua::"top namespace"::"test 2"::"nested test"',
      name = '"nested test"',
      path = "test_spec.lua",
      range = { 5, 4, 6, 8 },
      type = "test",
    }, tree:get_key('test_spec.lua::"top namespace"::"test 2"::"nested test"'):data())
  end)
  a.it("ignored positions without namespace when required", function()
    local tree = ts.parse_positions_from_string(
      "test_spec.lua",
      test_file,
      plenary_queries,
      { require_namespaces = true }
    )
    assert.Nil(tree:get_key('test_spec.lua::"test 3"'))
  end)
  a.it("uses custom id function", function()
    local tree = ts.parse_positions_from_string("test_spec.lua", test_file, plenary_queries, {
      position_id = function(position)
        return position.path .. "__" .. position.name
      end,
    })
    assert.Not.Nil(tree:get_key('test_spec.lua__"test 3"'))
  end)
end)
