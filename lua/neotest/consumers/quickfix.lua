local async = require("neotest.async")
local config = require("neotest.config")

local neotest = {}

---@toc_entry Quickfix Consumer
---@text
--- A consumer that sends results to the quickfix list.
neotest.quickfix = {}

---@private
---@type neotest.Client
local client

local init = function()
  ---@param results table<string, neotest.Result>
  client.listeners.results = function(adapter_id, results, partial)
    if partial then
      return
    end
    local tree = assert(client:get_position(nil, { adapter = adapter_id }))

    local qf_results = {}
    local buffer_cache = {}
    for pos_id, result in pairs(results) do
      if result.status == "failed" and tree:get_key(pos_id) then
        local pos = assert(tree:get_key(pos_id)):data()
        if pos.type == "test" then
          local bufnr = buffer_cache[pos.path]
          if not bufnr then
            ---@diagnostic disable-next-line: param-type-mismatch
            bufnr = async.fn.bufnr(pos.path)
            buffer_cache[pos.path] = bufnr
          end

          for _, error in ipairs(result.errors or {}) do
            qf_results[#qf_results + 1] = {
              bufnr = bufnr > 0 and bufnr or nil,
              filename = bufnr <= 0 and pos.path or nil,
              lnum = (error.line or pos.range[1]) + 1,
              col = pos.range[2] + 1,
              text = error.message,
              type = result.status == "failed" and "E" or "W",
            }
          end
        end
      end
    end

    table.sort(qf_results, function(a, b)
      if a.filename == b.filename then
        if a.lnum == b.lnum then
          return a.col < b.col
        end
        return a.lnum < b.lnum
      end
      return a.filename < b.filename
    end)

    if #qf_results > 0 then
      async.fn.setqflist(qf_results)
      if config.quickfix.open then
        if type(config.quickfix.open) == "function" then
          config.quickfix.open()
        else
          async.api.nvim_command("copen")
        end
      end
    end
  end
end

neotest.quickfix = setmetatable(neotest.quickfix, {
  __call = function(_, client_)
    client = client_
    init()
    return neotest.quickfix
  end,
})

return neotest.quickfix
