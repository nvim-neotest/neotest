local Tree = require("neotest.types").Tree

describe("neotest tree", function()
  it("parses lists", function()
    local data = { 1, { 2, { 3 }, { 4, { 5 } } } }
    local tree = Tree.from_list(data, function(x)
      return x
    end)
    local list = tree:to_list()
    assert.are.same(data, list)
  end)

  it("provides key access", function()
    local data = { 1, { 2, { 3 }, { 4, { 5 } } } }
    local tree = Tree.from_list(data, function(x)
      return x
    end)
    for i = 1, 5 do
      assert.are.same(tree:get_key(i):data(), i)
    end
  end)

  it("iterates in order", function()
    local data = { 1, { 2, { 3 }, { 4, { 5 } } } }
    local tree = Tree.from_list(data, function(x)
      return x
    end)
    local i = 1
    for _, elem in tree:iter() do
      assert.are.same(elem, i)
      i = i + 1
    end
  end)
end)
