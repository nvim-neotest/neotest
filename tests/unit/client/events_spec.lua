local events = require("neotest.client.events")

describe("events processor", function()
  ---@type neotest.EventProcessor
  local processor
  before_each(function()
    processor = events.processor()
  end)

  it("emits event", function()
    local called = false
    processor.listeners.discover_positions["test"] = function()
      called = true
    end
    processor:emit(events.events.DISCOVER_POSITIONS)
    assert.is.True(called)
  end)

  it("emits events with arguments", function()
    local result
    processor.listeners.discover_positions["test"] = function(arg)
      result = arg
    end
    local expected = "This is an arg"
    processor:emit(events.events.DISCOVER_POSITIONS, expected)
    assert.equal(expected, result)
  end)
end)
