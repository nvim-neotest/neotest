local async = require("neotest.async")
local lib = require("neotest.lib")

---@private
---@type neotest.Client
local client
local last_run

local neotest = {}

---@toc_entry Run Consumer
---@text
--- A consumer providing a simple interface to run tests.
neotest.run = {}

---@private
function neotest.run.get_tree_from_args(args, store)
  local tree, adapter = (function()
    if args.suite then
      if not args.adapter then
        args.adapter = client:get_adapters()[1]
      end
      return client:get_position(nil, args)
    end
    if args[1] then
      local position_id = lib.files.exists(args[1]) and async.fn.fnamemodify(args[1], ":p")
        or args[1]
      return client:get_position(position_id, args)
    end
    local file_path = async.fn.expand("%:p")
    local row = async.fn.getpos(".")[2] - 1
    return client:get_nearest(file_path, row, args)
  end)()
  if tree and store then
    last_run = { tree:data().id, vim.tbl_extend("keep", args, { adapter = adapter }) }
  end
  return tree
end

--- Run the given position or the nearest position if not given.
--- All arguments are optional
---
--- Run the current file
--- >
---   lua require("neotest").run.run(vim.fn.expand("%"))
--- <
---
--- Run the nearest test
--- >
---   lua require("neotest").run.run()
--- <
---
--- Debug the current file with nvim-dap
--- >
---   lua require("neotest").run.run({vim.fn.expand("%"), strategy = "dap"})
--- <
---@param args string|table? Position ID to run or args. If args then args[1] should
--- be the position ID.
---
---@field suite boolean Run the entire suite instead of a single position
---@field adapter string Adapter ID, if not given the first adapter found with
--- chosen position is used.
---@field strategy string|neotest.Strategy Strategy to run commands with
---@field extra_args string[] Extra arguments for test command
---@field env table<string, string> Extra environment variables to add to the
--- environment of tests
---@field concurrent boolean Run tests concurrently when an adapter provides multiple commands to run
function neotest.run.run(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  async.run(function()
    local tree = neotest.run.get_tree_from_args(args, true)
    if not tree then
      lib.notify("No tests found")
      return
    end
    client:run_tree(tree, args)
  end)
end

--- Re-run the last position that was run.
--- Arguments are optional
---
--- Run the last position that was run with the same arguments and strategy
--- >
---   lua require("neotest").run.run_last()
--- <
---
--- Run the last position that was run with the same arguments but debug with
--- nvim-dap
--- >
---   lua require("neotest").run.run_last({ strategy = "dap" })
--- <
---@param args table Arguments to run with
---
---@field adapter string Adapter ID, if not given the same adapter as the last run
--- is used.
---@field strategy string|neotest.Strategy Strategy to run commands with
---@field extra_args string[] Extra arguments for test command
---@field env table<string, string> Extra environment variables to add to the
--- environment of tests
---@field concurrent boolean Run tests concurrently when an adapter provides multiple commands to run
function neotest.run.run_last(args)
  args = args or {}
  if not last_run then
    lib.notify("No tests run yet")
    return
  end
  async.run(function()
    local position_id, last_args = unpack(last_run)
    args = vim.tbl_extend("keep", args, last_args)
    local tree = client:get_position(position_id, args)
    if not tree then
      lib.notify("Last test run no longer exists")
      return
    end
    client:run_tree(tree, args)
  end)
end

local function get_tree_interactive()
  local running = client:running_positions()
  local elem = async.ui.select(running, {
    prompt = "Select a position",
    format_item = function(elem)
      return elem.position:data().name
    end,
  })
  if not elem then
    return
  end
  return elem.position, elem.position
end

--- Stop a running process
---
---@param args string|table? Position ID to stop or args. If args then args[1]
--- should be the position ID.
---@field adapter string Adapter ID, if not given the first adapter found with
--- chosen position is used.
---@field interactive boolean Select a running position interactively
function neotest.run.stop(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  async.run(function()
    local pos
    if args.interactive then
      pos = get_tree_interactive()
    else
      pos = neotest.run.get_tree_from_args(args)
    end
    if not pos then
      lib.notify(args.interactive and "No test selected" or "No tests found", "warn")
      return
    end
    client:stop(pos, args)
  end)
end

--- Attach to a running process for the given position.
---
---@param args string|table? Position ID to attach to or args. If args then
--- args[1] should be the position ID.
---
---@field adapter string Adapter ID, if not given the first adapter found with
--- chosen position is used.
---@field interactive boolean Select a running position interactively
function neotest.run.attach(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  async.run(function()
    local pos
    if args.interactive then
      pos = get_tree_interactive()
    else
      pos = neotest.run.get_tree_from_args(args)
    end
    if not pos then
      lib.notify(args.interactive and "No test selected" or "No tests found", "warn")
      return
    end
    client:attach(pos, args)
  end)
end

--- Get the list of all known adapter IDs.
function neotest.run.adapters()
  if not client:has_started() then
    return {}
  end
  return client:get_adapters()
end

--- Get last test run tree and adapter id.
---@return string | nil, table | nil Position id and last args table
function neotest.run.get_last_run()
  if not last_run then
    return nil, nil
  end
  return unpack(last_run)
end

neotest.run = setmetatable(neotest.run, {
  __call = function(_, client_)
    client = client_
    return neotest.run
  end,
})

return neotest.run
