local nio = require("nio")
local a = nio.tests
local sp = require("neotest.lib.subprocess")

local assert = require("tests.assertions")

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
  a.it("can load plenary in subprocess when available in parent", function()
    if not pcall(require, "plenary.path") then
      MiniTest.skip("plenary is no longer a neotest dependency; only tested when installed")
    end

    local result = sp.call([[function()
    return pcall(require, "plenary.path")
  end]])
    assert.True(result)
  end)
  a.it("parent is_child == false", function()
    local result = sp.is_child()
    assert.False(result)
  end)
  a.it("can parse lua in subprocess", function()
    local result = sp.call([[function()
    local parser = vim.treesitter.get_string_parser("local x = 1", "lua")
    return parser:parse() ~= nil
  end]])
    assert.True(result)
  end)
end)
