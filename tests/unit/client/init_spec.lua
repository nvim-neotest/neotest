local async = require("neotest.async")
local a = async.tests
local stub = require("luassert.stub")
local Tree = require("neotest.types").Tree
local lib = require("neotest.lib")
local NeotestClient = require("neotest.client")
local AdapterGroup = require("neotest.adapters")
A = function(...)
  print(vim.inspect(...))
end

describe("neotest client", function()
  local mock_adapter, mock_strategy, client
  local dir = async.fn.getcwd()
  local files
  local dirs = { dir }
  before_each(function()
    dirs = { dir }
    files = { dir .. "/test_file_1", dir .. "/test_file_2" }
    stub(lib.files, "find", files)
    stub(lib.files, "is_dir", function(path)
      return vim.tbl_contains(dirs, path)
    end)
    require("neotest.config").setup({ adapters = { mock_adapter } })
    mock_adapter = {
      name = "adapter",
      is_test_file = function()
        return true
      end,
      root = function()
        return dir
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
      build_spec = function()
        return {}
      end,
      results = function(_, _, tree)
        local results = {}
        for _, pos in tree:iter() do
          if pos.type == "file" or pos.type == "test" then
            results[pos.id] = {
              status = "failed",
              short = pos.name,
              errors = pos.range and { { message = "a", line = pos.range[1] } },
            }
          end
        end
        return results
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
    client = NeotestClient(AdapterGroup({ mock_adapter }))
  end)
  after_each(function()
    lib.files.find:revert()
  end)

  describe("reading positions", function()
    a.it("reads all tests files", function()
      local tree = client:get_position(dir)
      assert.Not.Nil(tree:get_key(dir .. "/test_file_1"))
      assert.Not.Nil(tree:get_key(dir .. "/test_file_2"))
      assert.Nil(tree:get_key(dir .. "/test_file_3"))
    end)

    a.it("updates files when first requested", function()
      local tree = client:get_position(dir)
      local file_tree = tree:get_key(dir .. "/test_file_1")
      assert.Not.same(file_tree:children(), {})
    end)

    describe("when looking for new file", function()
      before_each(function()
        stub(lib.files, "exists", true)
        lib.files.exists.on_call_with(dir .. "/test_file_3/").returns(false)
      end)
      after_each(function()
        lib.files.exists:revert()
      end)
      a.it("it reads the files", function()
        files[#files + 1] = dir .. "/test_file_3"
        client:_update_positions(dir)
        client:_update_positions(dir .. "/test_file_3")
        local file_tree = client:get_position(dir .. "/test_file_3")
        assert.Not.same(file_tree:children(), {})
      end)
    end)

    describe("when looking for new directory", function()
      a.it("it reads the new directory", function()
        dirs = { dir, dir .. "/new_dir" }
        client:_update_positions(dir)
        files[#files + 1] = dir .. "/new_dir/test_file_3"
        client:_update_positions(dir .. "/new_dir")
        local file_tree = client:get_position(dir .. "/new_dir")
        assert.Not.same(file_tree:children(), {})
      end)
    end)
  end)

  describe("running tests", function()
    a.it("fills results for dir from child files", function()
      local tree = client:get_position(dir)
      client:run_tree(tree, { strategy = mock_strategy })
      local results = client:get_results(mock_adapter.name)
      for _, pos in tree:iter() do
        assert.Not.Nil(results[pos.id])
      end
    end)

    a.it("fills results for namespaces from child tests", function()
      local tree = client:get_position(dir .. "/test_file_1")
      client:run_tree(tree, { strategy = mock_strategy })
      local results = client:get_results(mock_adapter.name)
      for _, pos in tree:iter() do
        assert.Not.Nil(results[pos.id])
      end
    end)

    a.it("fills test and namespace results fromm failed files", function()
      mock_adapter.results = function(_, _, tree)
        local results = {}
        for _, pos in tree:iter() do
          if pos.type == "file" then
            results[pos.id] = {
              status = "failed",
              short = pos.name,
              errors = pos.range and { { message = "a", line = pos.range[1] } },
            }
          end
        end
        return results
      end

      local tree = client:get_position(dir)
      client:run_tree(tree, { strategy = mock_strategy })
      local results = client:get_results(mock_adapter.name)
      assert.equal(6, #vim.tbl_keys(results))
    end)
  end)
end)
