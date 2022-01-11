local async = require("plenary.async")
local a = async.tests
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local Tree = require("neotest.types").Tree
local lib = require("neotest.lib")
local NeotestClient = require("neotest.client")
A = function(...)
  async.util.scheduler()
  print(vim.inspect(...))
end

describe("neotest client", function()
  local mock_adapter, mock_adapters, mock_strategy, client
  before_each(function()
    local cwd = vim.fn.getcwd()
    stub(lib.files, "find", { cwd .. "/test_file_1", cwd .. "/test_file_2" })
    mock_adapter = {
      is_test_file = function()
        return true
      end,
      discover_positions = function(file_path)
        return Tree.from_list({
          { id = file_path, type = "file", path = file_path, name = file_path },
          {
            {
              id = "namespace",
              type = "namespace",
              path = file_path,
              name = "namespace",
              range = { 5, 0, 50, 0 },
            },
            {
              id = "test_a",
              type = "test",
              path = file_path,
              name = "test_a",
              range = { 10, 0, 20, 50 },
            },
            {
              id = "test_b",
              type = "test",
              path = file_path,
              name = "test_b",
              range = { 30, 0, 40, 50 },
            },
          },
        }, function(pos)
          return pos.id
        end)
      end,
      build_spec = function(args)
        return {}
      end,
      results = function(spec, _, tree)
        local results = {}
        for _, pos in tree:iter() do
          results[pos.id] = {
            status = "failed",
            short = pos.name,
            errors = pos.range and { { message = "a", line = pos.range[1] } },
          }
        end
      end,
    }
    mock_adapters = {
      get_adapter = function()
        return mock_adapter
      end,
    }
    mock_strategy = function(spec)
      return {
        is_complete = function()
          return true
        end,
        output = function()
          return spec.strategy.output
        end,
        stop = function() end,
        attach = function() end,
        result = function()
          return spec.strategy.exit_code
        end,
      }
    end
    client = NeotestClient(mock_adapters)
  end)
  after_each(function()
    lib.files.find:revert()
  end)

  describe("running tests", function()
    a.it("reads all tests files", function()
      local dir = async.fn.getcwd()
      local tree = client:get_position(dir)
      assert.Not.Nil(tree:get_key(dir .. "/test_file_1"))
      assert.Not.Nil(tree:get_key(dir .. "/test_file_2"))
      assert.Nil(tree:get_key(dir .. "/test_file_3"))
    end)

    a.it("updates files when first requested", function()
      local dir = async.fn.getcwd()
      local tree = client:get_position(dir)
      local file_tree = tree:get_key(dir .. "/test_file_1")
      assert.same(file_tree:children(), {})
      file_tree = client:get_position(file_tree:data().id)
      assert.Not.same(file_tree:children(), {})
    end)
  end)
end)
