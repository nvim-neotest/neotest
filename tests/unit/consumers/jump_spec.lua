local Tree = require("neotest.types").Tree

local jump = require("neotest.consumers.jump")

A = function(...)
  print(vim.inspect(...))
end
describe("jump consumer", function()
  local tree = Tree.from_list({

    { type = "file", id = "file", range = { 0, 0, 14, 0 }, path = "file" },
    {
      { type = "test", id = "test 1", range = { 1, 0, 3, 0 }, path = "file" },
      { type = "test", id = "test 2", range = { 4, 0, 6, 0 }, path = "file" },
      {
        { type = "namespace", id = "namespace 3", range = { 7, 0, 9, 0 }, path = "file" },
        {
          { type = "test", id = "test 4", range = { 10, 0, 12, 0 }, path = "file" },
          { type = "test", id = "test 5", range = { 13, 0, 14, 0 }, path = "file" },
        },
      },
    },
  }, function(pos)
    return pos.id
  end)
  jump({
    get_nearest = function(_, _, row)
      local nearest
      for _, pos in tree:iter_nodes() do
        local data = pos:data()
        if data.range and data.range[1] <= row then
          nearest = pos
        else
          return nearest
        end
      end
      return nearest
    end,
    get_results = function()
      return {
        ["test 2"] = { status = "failed" },
        ["test 5"] = { status = "failed" },
      }
    end,
  })

  local text = [[

  test 1


  test 2


  namespace 3


    test 4


    test 5
    
  ]]
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", {}))
  vim.api.nvim_win_set_buf(0, buf)

  it("next goes to first test", function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    jump.next()
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 2, 0 }, pos)
  end)

  it("next failure goes to first failure", function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    jump.next({ status = "failed" })
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 5, 0 }, pos)
  end)

  it("next failure goes to second failure", function()
    vim.api.nvim_win_set_cursor(0, { 5, 0 })
    jump.next({ status = "failed" })
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 14, 0 }, pos)
  end)

  it("next goes to from first second test", function()
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    jump.next()
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 5, 0 }, pos)
  end)

  it("next does nothing if no next test", function()
    vim.api.nvim_win_set_cursor(0, { 14, 0 })
    jump.next()
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 14, 0 }, pos)
  end)

  it("prev goes to previous test", function()
    vim.api.nvim_win_set_cursor(0, { 15, 0 })
    jump.prev()
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 14, 0 }, pos)
  end)

  it("prev goes to previous test from top of test", function()
    vim.api.nvim_win_set_cursor(0, { 14, 0 })
    jump.prev()
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 11, 0 }, pos)
  end)

  it("prev doesn't jump to file", function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    jump.prev()
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 2, 0 }, pos)
  end)

  it("prev failure goes to prev failure", function()
    vim.api.nvim_win_set_cursor(0, { 15, 0 })
    jump.prev({ status = "failed" })
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 14, 0 }, pos)
  end)

  it("prev failure goes to first failure", function()
    vim.api.nvim_win_set_cursor(0, { 14, 0 })
    jump.prev({ status = "failed" })
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.same({ 5, 0 }, pos)
  end)
end)
