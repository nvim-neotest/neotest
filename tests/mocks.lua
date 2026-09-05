-- A minimal, plain-Lua replacement for the subset of `luassert.stub` used by
-- this repo's test suite.
--
-- Usage:
--     local stub = require("tests.mocks").stub
--     local s = stub(module, "func", return_value_or_fn)
--     s.on_call_with(arg).returns(other_value)
--     s:revert()
--
-- Semantics mirror luassert.stub (which is spy-based):
--  - The stub element replaces `object[key]` and is a TABLE with a `__call`
--    metamethod, so spy methods stay reachable through the replaced field
--    (e.g. `lib.files.find:revert()`), exactly as with luassert.
--  - Calls are recorded. Return values are the extra arguments given to
--    `stub()`; a single function value is invoked (with the call arguments)
--    instead of returned.
--  - `on_call_with(...)` overrides return values for exact-argument matches.
--  - `revert()` restores the original element and is idempotent.

local M = {}

-- Weak registry of live stubs, so `assertions.stub(x)` can validate its input.
local registry = setmetatable({}, { __mode = "k" })

local function pack_values(...)
  return { n = select("#", ...), ... }
end

local function unpack_values(values)
  return unpack(values, 1, values.n)
end

local function is_callable(v)
  if type(v) == "function" then
    return true
  end
  local mt = type(v) == "table" and getmetatable(v) or nil
  return mt ~= nil and mt.__call ~= nil
end

local function args_match(match, args)
  if match.n ~= args.n then
    return false
  end
  for i = 1, args.n do
    if match[i] ~= args[i] and not vim.deep_equal(match[i], args[i]) then
      return false
    end
  end
  return true
end

M.stub = function(object, key, ...)
  assert(type(object) == "table" and key ~= nil, "stub(): Can only create stub on a table key")
  assert(
    object[key] == nil or is_callable(object[key]),
    "stub(): The element must either be callable or nil"
  )

  local values = pack_values(...)
  local old_elem = object[key]
  local oncalls = {}
  local oncall_returns = {}

  local default
  if values.n == 1 and type(values[1]) == "function" then
    default = values[1]
  else
    default = function()
      return unpack_values(values)
    end
  end

  local spy = { calls = { n = 0 }, reverted = false, _is_stub = true }

  spy.returns = function(...)
    values = pack_values(...)
    default = function()
      return unpack_values(values)
    end
    return spy
  end

  spy.invokes = function(fn)
    default = fn
    return spy
  end

  spy.on_call_with = function(...)
    local match = pack_values(...)
    return {
      returns = function(...)
        table.insert(oncalls, match)
        oncall_returns[#oncalls] = pack_values(...)
        return spy
      end,
    }
  end

  spy.revert = function()
    if not spy.reverted then
      if object[key] == spy then
        object[key] = old_elem
      end
      spy.reverted = true
    end
    return old_elem
  end

  setmetatable(spy, {
    __call = function(self, ...)
      local args = pack_values(...)
      spy.calls.n = spy.calls.n + 1
      spy.calls[spy.calls.n] = args
      for i, match in ipairs(oncalls) do
        if args_match(match, args) then
          return unpack_values(oncall_returns[i])
        end
      end
      return default(...)
    end,
  })

  object[key] = spy
  registry[spy] = true
  return spy
end

--- luassert-style `assert.stub(stubbed_element)` : returns a chainable
--- assertion object with `was_called_with(...)` over the recorded calls.
function M.assert_stub(element)
  assert(
    type(element) == "table" and registry[element],
    "assert.stub: value is not a stub created with tests.mocks.stub"
  )
  return {
    was_called_with = function(...)
      local expected = pack_values(...)
      for i = 1, element.calls.n do
        if args_match(expected, element.calls[i]) then
          return
        end
      end
      local got = {}
      for i = 1, element.calls.n do
        got[#got + 1] = vim.inspect(element.calls[i])
      end
      error(
        "Expected stub to have been called with "
          .. vim.inspect(expected)
          .. "\n  recorded calls: "
          .. (#got > 0 and table.concat(got, "\n  ") or "(none)"),
        2
      )
    end,
  }
end

return M
