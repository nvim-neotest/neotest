local plen_async = require("plenary.async")

local function proxy_vim(prop)
  return setmetatable({}, {
    __index = function(_, k)
      return function(...)
        -- if we are in a fast event await the scheduler
        if vim.in_fast_event() then
          plen_async.util.scheduler()
        end

        return vim[prop][k](...)
      end
    end,
  })
end

local async_wrapper = {
  api = proxy_vim("api"),
  fn = proxy_vim("fn"),
}
if false then
  -- For type checking
  async_wrapper.api = vim.api
  async_wrapper.fn = vim.fn
end

setmetatable(async_wrapper, {
  __index = function(_, k)
    return plen_async[k]
  end,
})

return async_wrapper
