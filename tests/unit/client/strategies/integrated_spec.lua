local nio = require("nio")
local a = nio.tests
local lib = require("neotest.lib")
local strategy = require("neotest.client.strategies.integrated")

A = function(...)
  print(vim.inspect(...))
end
describe("integrated strategy", function()
  after_each(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        vim.api.nvim_win_close(win, true)
      end
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

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
      command = { "bash", "-c", "sleep 10" },
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
      command = { "bash", "-c", "printf hello; sleep 0.1; printf world" },
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
    nio.sleep(100)
    process.attach()
    assert.Not.equal(nio.api.nvim_win_get_config(0), "")
  end)
end)
