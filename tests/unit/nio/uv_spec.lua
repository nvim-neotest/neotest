local nio = require("nio")
local a = nio.tests

describe("file operations", function()
  local path = vim.fn.tempname()
  a.after_each(function()
    os.remove(path)
  end)
  a.it("reads a file", function()
    local f = assert(io.open(path, "w"))
    f:write("test read")
    f:close()

    local _, file = nio.uv.fs_open(path, "r", 438)
    local _, data = nio.uv.fs_read(file, 1024, -1)
    nio.uv.fs_close(file)
    assert.equals("test read", data)
  end)

  a.it("writes a file", function()
    local _, file = nio.uv.fs_open(path, "w", 438)
    nio.uv.fs_write(file, "test write")
    nio.uv.fs_close(file)

    local file = assert(io.open(path, "r"))
    local data = file:read()
    file:close()

    assert.equals("test write", data)
  end)
end)
