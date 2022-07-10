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
end)
