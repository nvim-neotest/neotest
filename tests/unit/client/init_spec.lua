local nio = require("nio")
local a = nio.tests
local stub = require("luassert.stub")
local Tree = require("neotest.types").Tree
local lib = require("neotest.lib")
local NeotestClient = require("neotest.client")
local AdapterGroup = require("neotest.adapters")

describe("neotest client", function()
  ---@type neotest.Client
  local client
  ---@type neotest.Adapter
  local mock_adapter
  local mock_strategy, attached, stopped, exit_future, provided_spec
  local dir = vim.loop.cwd()
  local files
  local dirs = { dir }
  ---@return neotest.Tree
  local get_pos = function(...)
    return client:get_position(...)
  end
  before_each(function()
    dirs = { dir }
    files = { dir .. "/test_file_1", dir .. "/test_file_2" }
    stub(lib.files, "find", files)
    stub(lib.files, "is_dir", function(path)
      return vim.tbl_contains(dirs, path)
    end)
    stub(lib.files, "exists", function(path)
      return path ~= ""
    end)

    exit_future = nio.control.future()
    mock_adapter = {
      name = "adapter",
      is_test_file = function(file_path)
        return file_path ~= "" and not vim.endswith(file_path, lib.files.sep)
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
        return { strategy = { output = "not_a_file" } }
      end,
      results = function(_, _, tree)
        local results = {}
        for _, pos in tree:iter() do
          if pos.type == "test" then
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
      provided_spec = spec
      return {
        is_complete = function()
          return true
        end,
        output = function()
          return type(spec.strategy) == "table" and spec.strategy.output or "not_a_file"
        end,
        stop = function()
          exit_future.set()
        end,
        output_stream = function()
          local data = { "1\n", "2\n3", "\n4\n", "5\n" }
          local i = 0
          return function()
            i = i + 1
            return data[i]
          end
        end,
        attach = function()
          attached = true
        end,
        result = function()
          exit_future.wait()
          return type(spec.strategy) == "table" and spec.strategy.exit_code or 0
        end,
      }
    end
    client = NeotestClient(AdapterGroup())
    require("neotest").setup({ log_level = vim.log.levels.TRACE, adapters = { mock_adapter } })
  end)
  after_each(function()
    lib.files.find:revert()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

  describe("reading positions", function()
    a.it("reads all tests files", function()
      local tree = get_pos(dir)
      assert.Not.Nil(tree:get_key(dir .. "/test_file_1"))
      assert.Not.Nil(tree:get_key(dir .. "/test_file_2"))
      assert.Nil(tree:get_key(dir .. "/test_file_3"))
    end)

    a.it("uses projects adapters", function()
      require("neotest").setup_project(dir, { adapters = { mock_adapter } })
      local tree = get_pos(dir)
      assert.Not.Nil(tree:get_key(dir .. "/test_file_1"))
      assert.Not.Nil(tree:get_key(dir .. "/test_file_2"))
      assert.Nil(tree:get_key(dir .. "/test_file_3"))
    end)

    a.it("uses project strategy", function()
      local called = false
      local custom_strategy = function(...)
        called = true
        return mock_strategy(...)
      end
      require("neotest").setup_project(dir, { default_strategy = custom_strategy })
      local tree = get_pos(dir)
      exit_future.set()
      client:run_tree(tree)
      assert.True(called)
    end)

    a.it("doesn't use global adapters", function()
      require("neotest").setup_project(dir, { adapters = {} })
      local tree = get_pos(dir)
      assert.Nil(tree)
    end)

    a.it("updates files when first requested", function()
      local tree = get_pos(dir)
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
        client:_ensure_started()
        client:_update_positions(dir .. "/test_file_3")
        local file_tree = get_pos(dir .. "/test_file_3")
        assert.Not.same(file_tree:children(), {})
      end)
    end)

    describe("when looking for new directory", function()
      a.it("it reads the new directory", function()
        dirs = { dir, dir .. "/new_dir" }
        client:_ensure_started()
        files[#files + 1] = dir .. "/new_dir/test_file_3"
        client:_update_positions(dir .. "/new_dir")
        local file_tree = get_pos(dir .. "/new_dir")
        assert.Not.same(file_tree:children(), {})
      end)
    end)

    describe("discovery.enabled = false", function()
      a.it("doesn't scan directories by default", function()
        require("neotest").setup({
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })
        assert.Nil(get_pos(dir))
        assert.Nil(get_pos(dir .. "/test_file_1"))
      end)

      a.it("doesn't scan directories by default in configured project", function()
        require("neotest").setup_project(dir, {
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })
        assert.Nil(get_pos(dir))
        assert.Nil(get_pos(dir .. "/test_file_1"))
      end)

      a.it("only scans buffers that are open when client starts", function()
        require("neotest").setup({
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })
        vim.cmd("edit " .. dir .. "/test_file_1")

        assert.Not.Nil(get_pos(dir))
        assert.Not.Nil(get_pos(dir .. "/test_file_1"))
        assert.Nil(get_pos(dir .. "/test_file_2"))
      end)

      a.it("parses buffers as they are added", function()
        require("neotest").setup({
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })

        assert.Nil(get_pos(dir))

        vim.cmd("edit " .. dir .. "/test_file_1")

        assert.Not.Nil(get_pos(dir .. "/test_file_1"))
        assert.Nil(get_pos(dir .. "/test_file_2"))
      end)

      a.it("adds new buffers as to existing tree", function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        require("neotest").setup({
          adapters = { mock_adapter },
          discovery = { enabled = false },
        })
        vim.cmd("edit " .. dir .. "/test_file_1")
        local tree = get_pos(dir)
        tree = get_pos(dir .. "/test_file_2")
        assert.Nil(tree)
        vim.cmd("edit " .. dir .. "/test_file_2")
        nio.sleep(10)
        tree = get_pos(dir .. "/test_file_2")
        assert.Not.Nil(tree)
      end)
    end)

    describe("adapter discovery for paths outside cwd", function()
      local parent_stub, update_adapters_stub
      before_each(function()
        -- Use a file path that would belong to a different project/root
        local test_path = "/completely/different/path/test_file"
        local parent_dir = "/completely/different/path"

        parent_stub = stub(lib.files, "parent")
        parent_stub.on_call_with(test_path).returns(parent_dir)

        dirs[#dirs + 1] = parent_dir

        update_adapters_stub = stub(client, "_update_adapters")
      end)

      after_each(function()
        parent_stub:revert()
        update_adapters_stub:revert()
      end)

      a.it("calls _update_adapters when adapter not found for path", function()
        local test_path = "/completely/different/path/test_file"
        local parent_dir = "/completely/different/path"

        client:_ensure_started()

        client:_get_adapter(test_path)

        -- Verify _update_adapters was called with the parent directory
        assert.stub(client._update_adapters).was_called_with(client, parent_dir)
      end)
    end)
  end)

  describe("running tests", function()
    describe("using args", function()
      a.it("provides env", function()
        local tree = get_pos(dir)
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy, env = { TEST = "test" } })
        assert.equal(provided_spec.env.TEST, "test")
      end)

      a.it("provides cwd", function()
        local tree = get_pos(dir)
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy, cwd = "new_cwd" })
        assert.equal(provided_spec.cwd, "new_cwd")
      end)
    end)

    a.it("reports running positions", function()
      local tree = get_pos(dir)
      nio.run(function()
        client:run_tree(tree, { strategy = mock_strategy })
      end)
      local running = client:running_positions()
      exit_future.set()
      local adapter_id = client:get_adapters()[1]
      assert.same(running, { { adapter = adapter_id, position = tree } })
    end)

    a.it("runs multiple specs returned", function()
      mock_adapter.build_spec = function()
        return { { strategy = { output = "not_a_file" } } }
      end
      local tree = get_pos(dir)
      exit_future.set()
      client:run_tree(tree, { strategy = mock_strategy })
      local adapter_id = client:get_adapters()[1]
      local results = client:get_results(adapter_id)
      for _, pos in tree:iter() do
        if pos.type == "dir" then
          assert.equal(results[pos.id].status, "failed")
        end
      end
    end)

    a.it("uses spec strategy override", function()
      local called = nio.control.future()
      mock_adapter.build_spec = function()
        return {
          strategy = function(...)
            called.set()
            return mock_strategy(...)
          end,
        }
      end
      local tree = get_pos(dir)
      exit_future.set()
      nio.run(function()
        client:run_tree(tree, { strategy = mock_strategy })
      end)
      called.wait()
      local adapter_id = client:get_adapters()[1]
      local results = client:get_results(adapter_id)
      for _, pos in tree:iter() do
        if pos.type == "dir" then
          assert.equal(results[pos.id].status, "failed")
        end
      end
    end)

    describe("with unsupported roots", function()
      describe("supporting files", function()
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

          local tree = get_pos(dir)
          exit_future.set()
          client:run_tree(tree)

          assert.same({
            [dir .. "/test_file_1"] = true,
            [dir .. "/test_file_2"] = true,
          }, positions_run)
        end)

        a.it("sets results of directories as results are streamed", function()
          local positions_run = {}

          dirs = { dir, dir .. "/new_dir" }
          files[#files + 1] = dir .. "/new_dir/test_file_3"
          client:_ensure_started()
          local child_file = client:get_position(dir .. "/new_dir/test_file_3")

          mock_adapter.build_spec = function(args)
            local tree = args.tree
            local pos = tree:data()
            if pos.type == "dir" then
              return
            end
            return {
              stream = function()
                local sent = false
                return function()
                  if sent then
                    return nil
                  end
                  if pos.id == child_file:data().id then
                    sent = true
                    local results = {}
                    for _, pos in child_file:iter() do
                      results[pos.id] = { status = "passed" }
                    end
                    return results
                  end
                end
              end,
            }
          end

          local tree = get_pos(dir)

          nio.run(function()
            client:run_tree(tree, { strategy = mock_strategy })
          end)
          nio.sleep(10)

          local adapter_id = client:get_adapters()[1]
          local results = client:get_results(adapter_id)

          assert.same({
            [dir .. "/new_dir"] = {
              status = "passed",
            },
            [dir .. "/new_dir/test_file_3"] = {
              status = "passed",
            },
            [dir .. "/new_dir/test_file_3::namespace"] = {
              status = "passed",
            },
            [dir .. "/new_dir/test_file_3::test_a"] = {
              status = "passed",
            },
            [dir .. "/new_dir/test_file_3::test_b"] = {
              status = "passed",
            },
          }, results)

          exit_future.set()
        end)
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

        local tree = get_pos(dir)
        exit_future.set()
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

        local tree = get_pos(dir .. "/test_file_1::namespace")
        exit_future.set()
        client:run_tree(tree)

        assert.same({
          [dir .. "/test_file_1::test_a"] = true,
          [dir .. "/test_file_1::test_b"] = true,
        }, positons_run)
      end)
    end)

    describe("attaching", function()
      a.it("with position", function()
        local tree = get_pos(dir)
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        client:attach(tree)
        exit_future.set()
        assert.True(attached)
      end)

      a.it("with child", function()
        local tree = get_pos(dir)
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        client:attach(tree:children()[1])
        exit_future.set()
        assert.True(attached)
      end)
    end)

    describe("stopping", function()
      a.it("with position", function()
        local tree = get_pos(dir)
        local stopped
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
          stopped = true
        end)
        client:stop(tree)
        assert(stopped)
      end)

      a.it("with child", function()
        local tree = get_pos(dir)
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
          stopped = true
        end)
        client:stop(tree:children()[1])
        assert(stopped)
      end)
    end)

    describe("with streamed results", function()
      a.it("streams output data", function()
        local streamed_data = {}
        mock_adapter.build_spec = function()
          return {
            stream = function(data)
              for lines in data do
                vim.list_extend(streamed_data, lines)
              end
            end,
          }
        end
        local tree = get_pos(dir)
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        nio.sleep(10)

        assert.same({ "1", "2", "3", "4", "5" }, streamed_data)
        exit_future.set()
      end)

      a.it("emits streamed results", function()
        local tree = get_pos(dir .. "/test_file_1")
        mock_adapter.build_spec = function()
          return {
            stream = function()
              local results = {}
              for i, pos in tree:iter() do
                if pos.type == "test" and i % 2 == 0 then
                  results[pos.id] = { status = "passed" }
                end
              end
              local i, result
              return function()
                i, result = next(results, i)
                if i then
                  return { [i] = result }
                end
              end
            end,
          }
        end
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        nio.sleep(10)

        local adapter_id = client:get_adapters()[1]
        local results = client:get_results(adapter_id)
        for i, pos in tree:iter() do
          if i % 2 == 0 and pos.type == "test" then
            assert.same({ status = "passed" }, results[pos.id])
          else
            assert.Nil(results[pos.id])
          end
        end

        exit_future.set()
      end)

      a.it("attaches position", function()
        local tree = get_pos(dir .. "/test_file_1")
        mock_adapter.build_spec = function()
          return {
            stream = function()
              local results = {}
              for i, pos in tree:iter() do
                if pos.type == "test" and i % 2 == 0 then
                  results[pos.id] = { status = "passed" }
                end
              end
              local i, result
              return function()
                i, result = next(results, i)
                if i then
                  return { [i] = result }
                end
              end
            end,
          }
        end
        nio.run(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        nio.sleep(10)

        for i, pos in tree:iter_nodes() do
          if i % 2 == 0 and pos:data().type == "test" then
            client:attach(pos)
            break
          end
        end
        assert.True(attached)

        exit_future.set()
      end)
    end)

    describe("filling results", function()
      a.it("fills results for dir from child files", function()
        local tree = get_pos(dir)
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy })
        local adapter_id = client:get_adapters()[1]
        local results = client:get_results(adapter_id)
        for _, pos in tree:iter() do
          if pos.type == "dir" then
            assert.equal(results[pos.id].status, "failed")
          end
        end
      end)

      a.it("fills results for files from child files", function()
        local tree = get_pos(dir)
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy })
        local adapter_id = client:get_adapters()[1]
        local results = client:get_results(adapter_id)
        for _, pos in tree:iter() do
          if pos.type == "file" then
            assert.equal(results[pos.id].status, "failed")
          end
        end
      end)

      a.it("fills empty file as skipped", function()
        get_pos(dir)
        mock_adapter.results = function()
          return {}
        end
        mock_adapter.discover_positions = function()
          return Tree.from_list({
            {
              id = dir .. "/dummy_file",
              type = "file",
              path = dir .. "/dummy_file",
              name = dir .. "/dummy_file",
            },
          }, function(pos)
            return pos.id
          end)
        end
        local adapter_id = client:get_adapters()[1]
        client:_update_positions(dir .. "/dummy_file", { adapter = adapter_id })
        local tree = get_pos(dir .. "/dummy_file")
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy })
        local results = client:get_results(adapter_id)
        assert.equal(results[dir .. "/dummy_file"].status, "skipped")
      end)

      a.it("fills results for namespaces from child tests", function()
        local tree = get_pos(dir .. "/test_file_1")
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy })
        local adapter_id = client:get_adapters()[1]
        local results = client:get_results(adapter_id)
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

        local tree = get_pos(dir)
        exit_future.set()
        client:run_tree(tree, { strategy = mock_strategy })
        local adapter_id = client:get_adapters()[1]
        local results = client:get_results(adapter_id)
        assert.equal(9, #vim.tbl_keys(results))
      end)
    end)
  end)
end)
