-- A minimal, plain-Lua replacement for the subset of the luassert API used
-- by this repo's test suite. It is a drop-in `assert`: the module table is
-- callable (like plain Lua's `assert`) and exposes the matcher chains used
-- in the specs, so call sites keep their original form.
--
-- Usage in a spec:
--     local assert = require("tests.assertions")
--
-- Supported: assert(x), assert.same, assert.are.same, assert.equal,
-- assert.are.equal, assert.True, assert.False, assert.Nil, assert.Not.*,
-- assert.is.True/False/Nil/Not.Nil, assert.is_true, assert.is_not.equal,
-- assert.is_not.matches, assert.has_no_error, assert.stub(x).was_called_with.

local mocks = require("tests.mocks")

local M = {}

local function inspect(v)
  local ok, s = pcall(vim.inspect, v)
  return ok and s or tostring(v)
end

local function fail(msg)
  error(msg, 4)
end

--- Deep-equality assertion (luassert `assert.same`). Order-agnostic.
function M.same(a, b, msg)
  if not vim.deep_equal(a, b) then
    fail(
      (msg and msg .. ": " or "")
        .. "Expected deep equality\n  actual:   "
        .. inspect(a)
        .. "\n  expected: "
        .. inspect(b)
    )
  end
  return a, b
end

--- Shallow equality assertion, plain `==` (luassert `assert.equal`).
function M.equal(a, b, msg)
  if a ~= b then
    fail(
      (msg and msg .. ": " or "")
        .. "Expected equality\n  actual:   "
        .. inspect(a)
        .. "\n  expected: "
        .. inspect(b)
    )
  end
  return a, b
end

--- Negated deep equality (luassert `assert.Not.same`).
function M.not_same(a, b, msg)
  if vim.deep_equal(a, b) then
    fail(
      (msg and msg .. ": " or "")
        .. "Expected values NOT to be deeply equal\n  actual:   "
        .. inspect(a)
        .. "\n  expected: "
        .. inspect(b)
    )
  end
  return a, b
end

--- Negated shallow equality (luassert `assert.Not.equal`).
function M.not_equal(a, b, msg)
  if a == b then
    fail(
      (msg and msg .. ": " or "")
        .. "Expected values NOT to be equal\n  actual:   "
        .. inspect(a)
        .. "\n  expected: "
        .. inspect(b)
    )
  end
  return a, b
end

--- Truthiness assertion (luassert `assert.True`).
function M.True(v, msg)
  if not v then
    fail((msg and msg .. ": " or "") .. "Expected truthy, got " .. inspect(v))
  end
  return v
end

--- Strictly `false` (luassert `assert.False`).
function M.False(v, msg)
  if v ~= false then
    fail((msg and msg .. ": " or "") .. "Expected false, got " .. inspect(v))
  end
  return v
end

--- Strictly `nil` (luassert `assert.Nil`).
function M.Nil(v, msg)
  if v ~= nil then
    fail((msg and msg .. ": " or "") .. "Expected nil, got " .. inspect(v))
  end
  return v
end

--- Strictly `true` (luassert `assert.is_true`).
function M.is_true(v, msg)
  if v ~= true then
    fail((msg and msg .. ": " or "") .. "Expected true, got " .. inspect(v))
  end
  return v
end

--- Lua-pattern match (luassert `assert.matches(pattern, actual)`).
function M.matches(pattern, v, msg)
  if type(v) ~= "string" or not v:find(pattern) then
    fail(
      (msg and msg .. ": " or "")
        .. "Expected "
        .. inspect(v)
        .. " to match pattern "
        .. inspect(pattern)
    )
  end
  return v
end

--- Negated Lua-pattern match (luassert `assert.is_not.matches`).
function M.not_matches(pattern, v, msg)
  if type(v) == "string" and v:find(pattern) then
    fail(
      (msg and msg .. ": " or "")
        .. "Expected "
        .. inspect(v)
        .. " NOT to match pattern "
        .. inspect(pattern)
    )
  end
  return v
end

--- Run `fn(...)` and fail if it raises (luassert `assert.has_no_error`).
function M.has_no_error(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    fail("Expected no error, but got: " .. inspect(err))
  end
end

-- assert.are.<matcher>
M.are = setmetatable({}, {
  __index = function(_, key)
    if key == "same" then
      return M.same
    elseif key == "equal" then
      return M.equal
    end
    error("assertions: unsupported `assert.are` matcher: " .. tostring(key), 2)
  end,
})

-- assert.is<something> namespace variants used by the suite
M.is = setmetatable({}, {
  __index = function(_, key)
    if key == "True" then
      return M.True
    elseif key == "False" then
      return M.False
    elseif key == "Nil" then
      return M.Nil
    elseif key == "Not" then
      return { Nil = M.not_nil }
    end
    error("assertions: unsupported `assert.is` matcher: " .. tostring(key), 2)
  end,
})

function M.not_nil(v, msg)
  if v == nil then
    fail((msg and msg .. ": " or "") .. "Expected value NOT to be nil")
  end
  return v
end

-- assert.Not.<matcher> and callable assert.Not(x) (asserts falsiness)
M.Not = setmetatable({
  same = M.not_same,
  equal = M.not_equal,
  Nil = M.not_nil,
  True = function(v, msg)
    if v then
      fail((msg and msg .. ": " or "") .. "Expected falsy, got " .. inspect(v))
    end
    return v
  end,
  matches = M.not_matches,
}, {
  __call = function(_, v, msg)
    if v then
      fail((msg and msg .. ": " or "") .. "Expected falsy, got " .. inspect(v))
    end
    return v
  end,
})

-- assert.is_not.<matcher>
M.is_not = setmetatable({}, {
  __index = function(_, key)
    if key == "equal" then
      return M.not_equal
    elseif key == "matches" then
      return M.not_matches
    end
    error("assertions: unsupported `assert.is_not` matcher: " .. tostring(key), 2)
  end,
})

-- assert.stub(stubbed_func).was_called_with(...)
M.stub = mocks.assert_stub

setmetatable(M, {
  __call = function(_, v, msg)
    if not v then
      fail(msg or "Assertion failed!")
    end
    return v
  end,
})

return M
