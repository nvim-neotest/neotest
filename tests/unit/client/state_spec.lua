local events = require("neotest.client.events").events
local Tree = require("neotest.types").Tree
local NeotestState = require("neotest.client.state")

local function create_tree(positions)
  return Tree.from_list(positions, function(pos)
    return pos.id
  end)
end

describe("client state", function()
  local state, event_processor, emitted_event, emitted_args
  before_each(function()
    emitted_args, emitted_args = nil, nil
    event_processor = {
      emit = function(_, event, ...)
        emitted_event = event
        emitted_args = { ... }
      end,
    }
    state = NeotestState(event_processor)
  end)

  describe("position state", function()
    it("stores update as root when given first tree", function()
      local tree = create_tree({ id = "key" })
      state:update_positions(tree)
      local stored = state:positions()
      assert.equal(stored, tree)
    end)

    it("emits discover_positions event on update", function()
      local tree = create_tree({ id = "key" })
      state:update_positions(tree)
      assert.equal(emitted_event, events.DISCOVER_POSITIONS)
    end)

    it("emits event with new tree", function()
      local tree = create_tree({ id = "key" })
      state:update_positions(tree)
      assert.equal(tree, emitted_args[1])
    end)

    it("fills updated dir tree with existing file positions", function()
      state:update_positions(create_tree({
        { type = "file", id = "file" },
        { type = "test", id = "test-1" },
      }))

      state:update_positions(
        create_tree({ { type = "dir", id = "/root" }, { type = "file", id = "file" } })
      )
      local root = state:positions("/root")
      assert.is.Not.Nil(root:get_key("test-1"))
    end)

    it("connects updated dir tree with existing tree", function()
      state:update_positions(create_tree({
        { type = "file", id = "file" },
        { type = "test", id = "test-1" },
      }))

      state:update_positions(
        create_tree({ { type = "dir", id = "/root" }, { type = "file", id = "file" } })
      )
      local root = state:positions("/root")
      local test = root:get_key("test-1")
      assert.equal(test:root(), root)
    end)
  end)

  describe("results state", function()
    it("stores new results", function()
      state:update_results({ pos = true })
      local stored = state:results()["pos"]
      assert.is.True(stored)
    end)

    it("emits results event on update", function()
      state:update_results({ pos = true })
      assert.equal(emitted_event, events.RESULTS)
    end)

    it("emits event with new results", function()
      state:update_results({ pos = true })
      assert.same(emitted_args[1], { pos = true })
    end)

    it("sets pos to not running", function()
      state:update_running("root", { "pos" })
      state:update_results({ pos = true })
      assert.is.Nil(state:running()["pos"])
    end)

    it("overwrites existing result", function()
      state:update_results({ pos = true })
      state:update_results({ pos = false })
      local stored = state:results()["pos"]
      assert.is.False(stored)
    end)
  end)

  describe("running state", function()
    it("stores running", function()
      state:update_running("root", { "pos" })
      local stored = state:running()["pos"]
      assert.equal(stored, "root")
    end)

    it("emits run event on update", function()
      state:update_running("root", { "pos" })
      assert.equal(emitted_event, events.RUN)
    end)

    it("emits event with root and running positions", function()
      state:update_running("root", { "pos" })
      assert.same(emitted_args, { "root", { "pos" } })
    end)

    it("removes existing result", function()
      state:update_results({ pos = true })
      state:update_running("root", { "pos" })
      local stored = state:results()["pos"]
      assert.is.Nil(stored)
    end)
  end)
end)
