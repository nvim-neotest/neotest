local async = require("neotest.async")
local a = async.tests
local lib = require("neotest.lib")
local strategy = require("neotest.client.strategies.integrated")

A = function(...)
  print(vim.inspect(...))
end
describe("integrated strategy", function()
  a.it("produces output", function()
    local process = strategy({
      command = { "printf", "hello" },
      strategy = {
        height = 10,
        width = 10,
      },
    })
    process.result()
    local output = lib.files.read(process.output())
    assert.equal(output, "hello")
  end)

  a.it("returns exit code", function()
    local process = strategy({
      command = { "bash", "-c", "exit 100" },
      strategy = {
        height = 10,
        width = 10,
      },
    })
    local code = process.result()
    assert.equal(code, 100)
  end)

  a.it("stops the job", function()
    local process = strategy({
      command = { "bash", "-c", "sleep 1" },
      strategy = {
        height = 10,
        width = 10,
      },
    })
    process.stop()
    local code = process.result()
    assert.Not.equal(0, code)
  end)

  a.it("streams output", function()
    local process = strategy({
      command = { "bash", "-c", "printf hello; sleep 0; printf world" },
      strategy = {
        height = 10,
        width = 10,
      },
    })
    local stream = process.output_stream()
    assert.equal("hello", stream())
    assert.equal("world", stream())
  end)

  a.it("opens attach window", function()
    local process = strategy({
      command = { "echo", "hello" },
      strategy = {
        height = 10,
        width = 10,
      },
    })
    async.util.sleep(100)
    process.attach()
    assert.Not.equal(async.api.nvim_win_get_config(0), "")
  end)
end)
