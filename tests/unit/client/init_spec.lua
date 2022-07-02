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
  ---@type neotest.InternalClient
  local client
  local mock_adapter, mock_strategy, attached, stopped, exit_test
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

    local send_exit, await_exit = async.control.channel.oneshot()
    exit_test = send_exit
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
              id = file_path .. "::namespace",
              type = "namespace",
              path = file_path,
              name = "namespace",
              range = { 5, 0, 50, 0 },
            },
            {
              id = file_path .. "::test_a",
              type = "test",
              path = file_path,
              name = "test_a",
              range = { 10, 0, 20, 50 },
            },
            {
              id = file_path .. "::test_b",
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
        stop = function()
          send_exit()
        end,
        attach = function()
          attached = true
        end,
        result = function()
          await_exit()
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

    describe("discovery.enabled = false", function()
      a.it("doesn't scan directories by default", function()
        require("neotest.config").setup({
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })
        local tree = client:get_position(dir)
        assert.Nil(tree)
        tree = client:get_position(dir .. "/test_file_1")
        assert.Nil(tree)
      end)

      a.it("only scans buffers that are open when client starts", function()
        require("neotest.config").setup({
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })
        local bufnr = async.fn.bufadd(dir .. "/test_file_1")
        async.fn.bufload(bufnr)
        local tree = client:get_position(dir)
        assert.Not.Nil(tree)
        assert.Not.same(tree, {})
        tree = client:get_position(dir .. "/test_file_1")
        assert.Not.Nil(tree)
        assert.Not.same(tree, {})
        tree = client:get_position(dir .. "/test_file_2")
        assert.Nil(tree)
        async.api.nvim_buf_delete(bufnr, {})
      end)
    end)
  end)

  describe("running tests", function()
    describe("with unsupported roots", function()
      a.it("breaks up directories to files", function()
        local positions_run = {}
        mock_adapter.build_spec = function(args)
          local tree = args.tree
          local pos = tree:data()
          if pos.type == "dir" then
            return
          end
          positions_run[pos.id] = true
          return {}
        end

        local tree = client:get_position(dir)
        exit_test()
        client:run_tree(tree)

        assert.same({
          [dir .. "/test_file_1"] = true,
          [dir .. "/test_file_2"] = true,
        }, positions_run)
      end)

      a.it("breaks up files to tests", function()
        local positons_run = {}
        mock_adapter.build_spec = function(args)
          local tree = args.tree
          local pos = tree:data()
          if pos.type == "dir" or pos.type == "file" then
            return
          end
          positons_run[pos.id] = true
          return {}
        end

        local tree = client:get_position(dir)
        exit_test()
        client:run_tree(tree)

        assert.same({
          [dir .. "/test_file_1::test_a"] = true,
          [dir .. "/test_file_1::test_b"] = true,
          [dir .. "/test_file_2::test_a"] = true,
          [dir .. "/test_file_2::test_b"] = true,
        }, positons_run)
      end)

      a.it("breaks up namespaces to tests", function()
        local positons_run = {}
        mock_adapter.build_spec = function(args)
          local tree = args.tree
          local pos = tree:data()
          if pos.type == "namespace" then
            return
          end
          positons_run[pos.id] = true
          return {}
        end

        local tree = client:get_position(dir .. "/test_file_1::namespace")
        exit_test()
        client:run_tree(tree)

        assert.same({
          [dir .. "/test_file_1::test_a"] = true,
          [dir .. "/test_file_1::test_b"] = true,
        }, positons_run)
      end)
    end)

    describe("attaching", function()
      a.it("with position", function()
        local tree = client:get_position(dir)
        async.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        client:attach(tree)
        exit_test()
        assert.True(attached)
      end)

      a.it("with child", function()
        local tree = client:get_position(dir)
        async.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        client:attach(tree:children()[1])
        exit_test()
        assert.True(attached)
      end)
    end)

    describe("stopping", function()
      a.it("with position", function()
        local tree = client:get_position(dir)
        local stopped
        async.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
          stopped = true
        end)
        client:stop(tree)
        assert(stopped)
      end)

      a.it("with child", function()
        local tree = client:get_position(dir)
        async.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
          stopped = true
        end)
        client:stop(tree:children()[1])
        assert(stopped)
      end)
    end)

    a.it("fills results for dir from child files", function()
      local tree = client:get_position(dir)
      exit_test()
      client:run_tree(tree, { strategy = mock_strategy })
      local results = client:get_results(mock_adapter.name)
      for _, pos in tree:iter() do
        assert.Not.Nil(results[pos.id])
      end
    end)

    a.it("fills results for namespaces from child tests", function()
      local tree = client:get_position(dir .. "/test_file_1")
      exit_test()
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
      exit_test()
      client:run_tree(tree, { strategy = mock_strategy })
      local results = client:get_results(mock_adapter.name)
      assert.equal(9, #vim.tbl_keys(results))
    end)
  end)
end)
