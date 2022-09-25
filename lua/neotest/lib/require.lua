return function(module)
  return setmetatable({}, {
    __index = function(_, key)
      return require(module)[key]
    end,
    __newindex = function(_, key, value)
      require(module)[key] = value
    end,
    __call = function(_, ...)
      return require(module)(...)
    end,
  })
end
