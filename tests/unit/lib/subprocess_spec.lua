local nio = require("nio")
local a = nio.tests
local sp = require("neotest.lib.subprocess")

describe("", function()
  if not sp.enabled() then
    sp.init()
  end

  a.it("is enabled", function()
    assert(sp.enabled())
  end)
  a.it("returns from function", function()
    local result = sp.call("function(msg) return msg .. ' world' end", { "hello" })
    assert.are.same("hello world", result)
  end)
  a.it("child is_child == true", function()
    local result = sp.call("require('neotest.lib.subprocess').is_child")
    assert.True(result)
  end)
  a.it("parent is_child == false", function()
    local result = sp.is_child()
    assert.False(result)
  end)
end)
