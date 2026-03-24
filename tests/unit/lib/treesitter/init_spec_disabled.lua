local nio = require("nio")
local a = nio.tests
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

local directive_gsub_plenary_namespace_query = [[
  ;; describe blocks
  ((function_call
      name: (identifier) @func_name (#match? @func_name "^describe$") 
      arguments: (arguments (_) @namespace.name (function_definition)) (#gsub! @namespace.name "$" "_example")
  )) @namespace.definition
]]

local directive_set_plenary_namespace_query = [[
  ;; describe blocks
  ((function_call
      name: (identifier) @func_name (#match? @func_name "^describe$") 
      arguments: (arguments (_) @namespace.name (#set! @namespace.name type "parameter") (function_definition))
  )) @namespace.definition
]]

local directive_offset_plenary_namespace_query = [[
  ;; describe blocks
  ((function_call
      name: (identifier) @func_name (#match? @func_name "^describe$") 
      arguments: (arguments (_) @namespace.name (#offset! @namespace.name 1 1 1 1) (function_definition))
  )) @namespace.definition
]]

local simple_test_file = [[
it("test", function()
end)
]]
local complex_test_file = [[
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

local function get_match_type(captured_nodes)
  if captured_nodes["test.name"] then
    return "test"
  end
  if captured_nodes["namespace.name"] then
    return "namespace"
  end
end

describe("treesitter parsing", function()
  a.it("finds all positions", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", complex_test_file, plenary_queries, {})
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
      complex_test_file,
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
      complex_test_file,
      plenary_queries,
      { require_namespaces = true }
    )
    assert.Nil(tree:get_key('test_spec.lua::"test 3"'))
  end)
  a.it("uses custom id function", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", complex_test_file, plenary_queries, {
        position_id = function(position)
          return position.path .. "__" .. position.name
        end,
      })
    assert.Not.Nil(tree:get_key('test_spec.lua__"test 3"'))
  end)
  a.it("uses custom id function as string", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", complex_test_file, plenary_queries, {
        position_id = [[function(position)
        return position.path .. "__" .. position.name
      end]],
      })
    assert.Not.Nil(tree:get_key('test_spec.lua__"test 3"'))
  end)

  a.it("uses custom build function", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", complex_test_file, plenary_queries, {
        build_position = function(file_path)
          return {
            type = "test",
            path = file_path,
            name = "same_name",
            range = { 0, 0, 0, 0 },
          }
        end,
      })
    for _, position in tree:iter() do
      if position.type ~= "file" then
        assert.are.same("same_name", position.name)
      end
    end
  end)

  a.it("build function - directive #gsub!", function()
    local tree = ts.parse_positions_from_string(
      "test_spec.lua",
      complex_test_file,
      directive_gsub_plenary_namespace_query,
      {
        build_position = function(file_path, source, captured_nodes, metadata)
          local match_type = get_match_type(captured_nodes)
          local name = metadata[match_type .. ".name"].text
          local definition = captured_nodes[match_type .. ".definition"]

          return {
            type = type,
            path = file_path,
            name = name,
            range = definition:range(),
          }
        end,
      }
    )

    for _, position in tree:iter() do
      if position.type ~= "file" then
        assert.are.same('"top namespace"_example', position.name)
      end
    end
  end)

  a.it("build function - directive #set!", function()
    local tree = ts.parse_positions_from_string(
      "test_spec.lua",
      complex_test_file,
      directive_set_plenary_namespace_query,
      {
        build_position = function(file_path, source, captured_nodes, metadata)
          local match_type = get_match_type(captured_nodes)
          local name = metadata[match_type .. ".name"].type
          local definition = captured_nodes[match_type .. ".definition"]

          return {
            type = type,
            path = file_path,
            name = name,
            range = definition:range(),
          }
        end,
      }
    )

    for _, position in tree:iter() do
      if position.type ~= "file" then
        assert.are.same("parameter", position.name)
      end
    end
  end)

  -- a.it("build function - directive #offset!", function()
  --   local tree = ts.parse_positions_from_string(
  --     "test_spec.lua",
  --     complex_test_file,
  --     directive_offset_plenary_namespace_query,
  --     {
  --       build_position = function(file_path, source, captured_nodes, metadata)
  --         local match_type = get_match_type(captured_nodes)
  --         local name = metadata[match_type .. ".name"].range
  --         A(metadata[match_type..".name"])
  --         local definition = captured_nodes[match_type .. ".definition"]

  --         return {
  --           type = type,
  --           path = file_path,
  --           name = name,
  --           range = definition:range(),
  --         }
  --       end,
  --     }
  --   )

  --   for _, position in tree:iter() do
  --     if position.type ~= "file" then
  --       assert.are.same({ 1, 10, 1, 25 }, position.name)
  --     end
  --   end
  -- end)

  a.it("uses custom build function as string", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", complex_test_file, plenary_queries, {
        build_position = [[function(file_path)
        return {
          type = "test",
          path = file_path,
          name = "same_name",
          range = { 0, 0, 0, 0 },
        }
      end]],
      })
    for _, position in tree:iter() do
      if position.type ~= "file" then
        assert.are.same("same_name", position.name)
      end
    end
  end)

  a.it("allows custom build function to return list", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", complex_test_file, plenary_queries, {
        build_position = function(file_path)
          return {
            {
              type = "test",
              path = file_path,
              name = "same_name",
              range = { 0, 0, 0, 0 },
            },
          }
        end,
      })
    for _, position in tree:iter() do
      if position.type ~= "file" then
        assert.are.same("same_name", position.name)
      end
    end
  end)

  a.it("assigns children without ranges to previous node with range", function()
    local tree =
      ts.parse_positions_from_string("test_spec.lua", simple_test_file, plenary_queries, {
        nested_tests = true,
        build_position = function(file_path)
          return {
            {
              name = "parent",
              path = file_path,
              range = { 0, 0, 0, 0 },
              type = "test",
            },
            {
              name = "child 1",
              path = file_path,
              type = "test",
            },
            {
              name = "child 2",
              path = file_path,
              type = "test",
            },
            {
              name = "child 3",
              path = file_path,
              type = "test",
            },
          }
        end,
      })
    local expected = {
      {
        id = "test_spec.lua",
        name = "test_spec.lua",
        path = "test_spec.lua",
        range = { 0, 0, 2, 0 },
        type = "file",
      },
      {
        {
          id = "test_spec.lua::parent",
          name = "parent",
          path = "test_spec.lua",
          range = { 0, 0, 0, 0 },
          type = "test",
        },
        {
          {
            id = "test_spec.lua::parent::child 1",
            name = "child 1",
            path = "test_spec.lua",
            type = "test",
          },
        },
        {
          {
            id = "test_spec.lua::parent::child 2",
            name = "child 2",
            path = "test_spec.lua",
            type = "test",
          },
        },
        {
          {
            id = "test_spec.lua::parent::child 3",
            name = "child 3",
            path = "test_spec.lua",
            type = "test",
          },
        },
      },
    }
    assert.same(expected, tree:to_list())
  end)
end)
