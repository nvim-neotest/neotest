local neotest = require("neotest")

local nio = require("nio")
local a = nio.tests

local stub = require("luassert.stub")
local Tree = require("neotest.types").Tree
local lib = require("neotest.lib")

local NeotestClient = require("neotest.client")
local AdapterGroup = require("neotest.adapters")

describe("neotest consumer - output_panel", function()
  ---@type neotest.Client
  local client

  ---@type neotest.Adapter
  local mock_adapter
  local mock_strategy
  local exit_future_1, exit_future_2

  local dir = vim.loop.cwd()
  local files
  local dirs = { dir }
  local notify
  local notify_msg = ""

  ---@return neotest.Tree
  local get_pos = function(...)
    ---@diagnostic disable-next-line
    return client:get_position(...)
  end

  before_each(function()
    dirs = { dir }
    files = { dir .. "/test_file_1", dir .. "/test_file_2" }

    notify = function(message, level)
      notify_msg = message
    end

    stub(lib, "notify", notify)
    stub(lib.files, "find", files)
    stub(lib.files, "read", "Test results - passed and failed\r\n")
    stub(lib.files, "is_dir", function(path)
      return vim.tbl_contains(dirs, path)
    end)
    stub(lib.files, "exists", function(path)
      return path ~= ""
    end)

    exit_future_1, exit_future_2 = nio.control.future(), nio.control.future()

    ---@diagnostic disable-next-line: missing-fields
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
          },
        }, function(pos)
          return pos.id
        end)
      end,

      build_spec = function()
        return { strategy = { output = "not_a_file" } }
      end,

      results = function(_, _, tree)
        return {}
      end,
    }

    mock_strategy = function(spec)
      return {
        is_complete = function()
          return true
        end,

        output = function()
          return type(spec.strategy) == "table" and spec.strategy.output or "not_a_file"
        end,

        stop = function()
          exit_future_1.set()
          exit_future_2.set()
        end,

        result = function()
          if not exit_future_1.is_set() then
            exit_future_1.wait()
          else
            exit_future_2.wait()
          end
          return type(spec.strategy) == "table" and spec.strategy.exit_code or 0
        end,
      }
    end

    client = NeotestClient(AdapterGroup())
    ---@diagnostic disable-next-line
    neotest.setup({ adapters = { mock_adapter }, output_panel = { enabled = true } })

    require("neotest.consumers.output_panel")(client)
    ---@diagnostic disable-next-line
    client.listeners.results = { output_panel = client.listeners.results }
  end)

  after_each(function()
    lib.files.find:revert()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    notify_msg = ""
  end)

  describe("user forcefully closes the panel", function()
    local panel_bufnr = function()
      return vim.tbl_filter(function(bufnr)
        return nio.api.nvim_buf_get_name(bufnr):match("Neotest Output Panel")
      end, nio.api.nvim_list_bufs())[1]
    end

    before_each(function()
      neotest.output_panel.open()
    end)

    a.it("recreates terminal session if term channel is invalid", function()
      local tree = get_pos(dir .. "/test_file_1")

      nio.run(function()
        client:run_tree(tree, { strategy = mock_strategy })
      end)
      exit_future_1.set()

      nio.api.nvim_buf_delete(panel_bufnr(), { force = true })
      neotest.output_panel.open()

      nio.run(function()
        assert.has_no_error(function()
          client:run_tree(tree, { strategy = mock_strategy })
        end)
        assert.is_not.matches("Error sending output to term channel:", notify_msg)
      end)
      exit_future_2.set()
    end)

    it("recreates panel buffer if it was closed", function()
      vim.api.nvim_buf_delete(panel_bufnr(), { force = true })

      assert.has_no_error(function()
        neotest.output_panel.open()
      end)
    end)

    it("deletes panel buffer if it already exists with the same name", function()
      vim.api.nvim_buf_delete(panel_bufnr(), { force = true })

      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, "Neotest Output Panel")

      assert.has_no_error(function()
        neotest.output_panel.open()
      end)
    end)
  end)
end)
