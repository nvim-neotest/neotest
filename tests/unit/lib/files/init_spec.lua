local async = require("neotest.async")
local a = async.tests
local files = require("neotest.lib").files
A = function(...)
  print(vim.inspect(...))
end

describe("files library", function()
  describe("parsing directory tree from files", function()
    it("places files under the root", function()
      local root = "/root"
      local result = files.parse_dir_from_files(root, { "/root/test_a", "/root/test_b" })
      assert.same(result:to_list(), {
        {
          id = "/root",
          name = "root",
          path = "/root",
          type = "dir",
        },
        {
          {
            id = "/root/test_a",
            name = "test_a",
            path = "/root/test_a",
            type = "file",
          },
        },
        {
          {
            id = "/root/test_b",
            name = "test_b",
            path = "/root/test_b",
            type = "file",
          },
        },
      })
    end)

    it("places files under the parent directory", function()
      local root = "/root"
      local result = files.parse_dir_from_files(root, { "/root/dir/test_a", "/root/test_b" })
      assert.same(result:to_list(), {
        {
          id = "/root",
          name = "root",
          path = "/root",
          type = "dir",
        },
        {
          {
            id = "/root/dir",
            name = "dir",
            path = "/root/dir",
            type = "dir",
          },
          {
            {
              id = "/root/dir/test_a",
              name = "test_a",
              path = "/root/dir/test_a",
              type = "file",
            },
          },
        },
        {
          {
            id = "/root/test_b",
            name = "test_b",
            path = "/root/test_b",
            type = "file",
          },
        },
      })
    end)

    it("parses directory and file with same name", function()
      local root = "/root"
      local result =
        files.parse_dir_from_files(root, { "/root/dir.py", "/root/dir/test_a", "/root/test_b" })
      assert.same(result:to_list(), {
        {
          id = "/root",
          name = "root",
          path = "/root",
          type = "dir",
        },
        {
          {
            id = "/root/dir",
            name = "dir",
            path = "/root/dir",
            type = "dir",
          },
          {
            {
              id = "/root/dir/test_a",
              name = "test_a",
              path = "/root/dir/test_a",
              type = "file",
            },
          },
        },
        {
          {
            id = "/root/dir.py",
            name = "dir.py",
            path = "/root/dir.py",
            type = "file",
          },
        },
        {
          {
            id = "/root/test_b",
            name = "test_b",
            path = "/root/test_b",
            type = "file",
          },
        },
      })
    end)
  end)

  describe("reading files", function()
    local path, file
    before_each(function()
      path = vim.fn.tempname()
      file = io.open(path, "w")
    end)
    after_each(function()
      file:close()
    end)

    a.it("reads data", function()
      file:write("some data")
      file:flush()
      local read_data = files.read(path)
      assert.equal("some data", read_data)
    end)

    a.it("reads lines", function()
      file:write("first\r\nsecond\nthird\n")
      file:flush()
      local read_data = files.read_lines(path)
      assert.same({ "first", "second", "third" }, read_data)
    end)

    a.it("stream lines", function()
      file:write("first\r\nsecond\nthird\n")
      file:flush()
      local lines_iter, stop_reading = files.stream_lines(path)
      local result = {}
      async.run(function()
        for lines in lines_iter do
          for _, line in ipairs(lines) do
            result[#result + 1] = line
          end
        end
      end)
      async.util.sleep(0.1)
      stop_reading()
      assert.same({ "first", "second", "third" }, result)
    end)

    a.it("stream lines after new data written", function()
      file:write("first\r\nsecond\nthird\n")
      file:flush()
      local lines_iter, stop_reading = files.stream_lines(path)
      local result = {}
      async.run(function()
        for lines in lines_iter do
          for _, line in ipairs(lines) do
            result[#result + 1] = line
          end
        end
      end)
      async.util.sleep(10)
      file:write("fourth")
      file:flush()
      async.util.sleep(10)
      file:write("\nfifth\n")
      file:flush()
      async.util.sleep(10)
      stop_reading()
      assert.same({ "first", "second", "third", "fourth", "fifth" }, result)
    end)
  end)
end)
