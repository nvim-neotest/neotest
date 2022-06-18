local positions = require("neotest.lib.positions")
local Tree = require("neotest.types").Tree

local function create_tree(positions)
  return Tree.from_list(positions, function(pos)
    return pos.id
  end)
end

describe("contains", function()
  it("dir contains file", function()
    local dir = {
      id = "a",
      type = "dir",
      name = "test",
      path = "/neotest/test",
      range = { 0, 0, 0, 0 },
    }
    local file = {
      id = "b",
      type = "file",
      name = "other.lua",
      path = "/neotest/test/other.lua",
      range = { 0, 0, 0, 0 },
    }
    assert(positions.contains(dir, file))
  end)

  it("dir contains dir", function()
    local dir = {
      id = "a",
      type = "dir",
      name = "neotest",
      path = "/neotest",
      range = { 0, 0, 0, 0 },
    }
    local file = {
      id = "b",
      type = "dir",
      name = "test",
      path = "/neotest/test",
      range = { 0, 0, 0, 0 },
    }
    assert(positions.contains(dir, file))
  end)

  it("file contains test", function()
    local file = {
      id = "a",
      type = "file",
      name = "test.lua",
      path = "/test.lua",
      range = { 0, 0, 10, 0 },
    }
    local test = {
      id = "b",
      type = "test",
      name = "a_test",
      path = "/test.lua",
      range = { 3, 0, 5, 0 },
    }
    assert(positions.contains(file, test))
  end)

  it("dir doesn't contain file", function()
    local dir = {
      id = "a",
      type = "dir",
      name = "test",
      path = "/neotest/test",
      range = { 0, 0, 0, 0 },
    }
    local file = {
      id = "b",
      type = "file",
      name = "test.lua",
      path = "/neotest/other/test.lua",
      range = { 0, 0, 0, 0 },
    }
    assert.Not(positions.contains(dir, file))
  end)

  it("dir doesn't contain dir", function()
    local dir = {
      id = "a",
      type = "dir",
      name = "neotest",
      path = "/neotest/tests",
      range = { 0, 0, 0, 0 },
    }
    local file = {
      id = "b",
      type = "dir",
      name = "test",
      path = "/neotest/client",
      range = { 0, 0, 0, 0 },
    }
    assert.Not(positions.contains(dir, file))
  end)

  it("file doesn't contain test", function()
    local file = {
      id = "a",
      type = "file",
      name = "test.lua",
      path = "/test.lua",
      range = { 0, 0, 10, 0 },
    }
    local test = {
      id = "b",
      type = "test",
      name = "a_test",
      path = "/other_test.lua",
      range = { 3, 0, 5, 0 },
    }
    assert.Not(positions.contains(file, test))
  end)
end)

describe("merge", function()
  it("merge(dir, file) replaces tests in existing file", function()
    local dir = create_tree({
      { type = "dir", id = "root", path = "/root" },
      {
        { type = "file", id = "file", path = "/root/file" },
        { { type = "test", id = "test-1", path = "/root/file" } },
      },
    })
    local file = create_tree({
      { type = "file", id = "file", path = "/root/file" },
      { type = "test", id = "test-2", path = "/root/file" },
    })
    local ret = positions.merge(dir, file)
    local expected = {
      {
        id = "root",
        path = "/root",
        type = "dir",
      },
      {
        {
          id = "file",
          path = "/root/file",
          type = "file",
        },
        {
          {
            id = "test-2",
            path = "/root/file",
            type = "test",
          },
        },
      },
    }
    assert.are.same(expected, ret:to_list())
  end)

  it("merge(dir, dir) replaces contents of dir", function()
    local dir = create_tree({
      { type = "dir", id = "root", path = "/root" },
      {
        { type = "file", id = "file", path = "/root/file" },
        { { type = "test", id = "test-1", path = "/root/file" } },
      },
    })
    local new_dir = create_tree({
      { type = "dir", id = "root", path = "/root" },
      {
        { type = "file", id = "other", path = "/root/other" },
        { { type = "test", id = "test-2", path = "/root/other" } },
      },
    })
    local ret = positions.merge(dir, new_dir)
    local expected = {
      {
        id = "root",
        path = "/root",
        type = "dir",
      },
      {
        {
          id = "other",
          path = "/root/other",
          type = "file",
        },
        {
          {
            id = "test-2",
            path = "/root/other",
            type = "test",
          },
        },
      },
    }
    assert.are.same(expected, ret:to_list())
  end)

  it("merge(dir, dir) replaces contents of subdir", function()
    local dir = create_tree({
      { type = "dir", id = "root", path = "/root/sub" },
      {
        { type = "file", id = "file", path = "/root/sub/file" },
        { { type = "test", id = "test-1", path = "/root/sub/file" } },
      },
    })
    local new_dir = create_tree({
      { type = "dir", id = "root", path = "/root" },
      {
        { type = "dir", id = "sub", path = "/root/sub" },
        {
          { type = "file", id = "file", path = "/root/sub/file" },
          { { type = "test", id = "test-2", path = "/root/sub/file" } },
        },
      },
    })
    local ret = positions.merge(dir, new_dir)
    local expected = {
      {
        id = "root",
        path = "/root",
        type = "dir",
      },
      {
        {
          id = "sub",
          path = "/root/sub",
          type = "dir",
        },
        {
          {
            id = "file",
            path = "/root/sub/file",
            type = "file",
          },
          {
            {
              id = "test-2",
              path = "/root/sub/file",
              type = "test",
            },
          },
        },
      },
    }
    assert.are.same(expected, ret:to_list())
  end)

  it("merge(dir, file) adds new file", function()
    local dir = create_tree({
      { type = "dir", id = "/root", path = "/root" },
    })
    local file = create_tree({
      { type = "file", id = "/root/file", path = "/root/file" },
      { type = "test", id = "test-2", path = "/root/file" },
    })
    local ret = positions.merge(dir, file)
    local expected = {
      {
        id = "/root",
        path = "/root",
        type = "dir",
      },
      {
        {
          id = "/root/file",
          path = "/root/file",
          type = "file",
        },
        {
          {
            id = "test-2",
            path = "/root/file",
            type = "test",
          },
        },
      },
    }
    assert.are.same(expected, ret:to_list())
  end)

  it("merge(file, file) updates tests in file", function()
    local file = create_tree({
      { type = "file", id = "file", path = "/root/file" },
      { { type = "test", id = "test-1", path = "/root/file" } },
    })
    local new_file = create_tree({
      { type = "file", id = "file", path = "/root/file" },
      { { type = "test", id = "test-2", path = "/root/file" } },
    })
    local ret = positions.merge(file, new_file)
    local expected = {
      {
        id = "file",
        path = "/root/file",
        type = "file",
      },
      {
        {
          id = "test-2",
          path = "/root/file",
          type = "test",
        },
      },
    }
    assert.are.same(expected, ret:to_list())
  end)

  it("merge(dir, dir) merges unrelated dirs at common ancestor", function()
    local dir = create_tree({
      { type = "dir", id = "/root/sub1", path = "/root/sub1" },
      {
        { type = "file", id = "/root/sub1/file", path = "/root/sub1/file" },
        { { type = "test", id = "test-1", path = "/root/sub1/file" } },
      },
    })
    local new_dir = create_tree({
      { type = "dir", id = "/root/sub2", path = "/root/sub2" },
      {
        { type = "file", id = "/root/sub2/file", path = "/root/sub2/file" },
        { { type = "test", id = "test-2", path = "/root/sub2/file" } },
      },
    })
    local ret = positions.merge(dir, new_dir)
    local expected = {
      { type = "dir", id = "/root", name = "root", path = "/root" },
      {
        { type = "dir", id = "/root/sub1", path = "/root/sub1" },
        {
          { type = "file", id = "/root/sub1/file", path = "/root/sub1/file" },
          { { type = "test", id = "test-1", path = "/root/sub1/file" } },
        },
      },
      {
        { type = "dir", id = "/root/sub2", path = "/root/sub2" },
        {
          { type = "file", id = "/root/sub2/file", path = "/root/sub2/file" },
          { { type = "test", id = "test-2", path = "/root/sub2/file" } },
        },
      },
    }
    assert.are.same(expected, ret:to_list())
  end)
end)
