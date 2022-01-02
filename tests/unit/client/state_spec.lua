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
end)
