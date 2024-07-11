local nio = require("nio")
local lib = require("neotest.lib")
local config = require("neotest.config")

---@private
---@type neotest.Client
local client
local last_run

local neotest = {}

---@toc_entry Run Consumer
---@text
--- A consumer providing a simple interface to run tests.
---@class neotest.consumers.run
neotest.run = {}

---@package
---@nodoc
function neotest.run.get_tree_from_args(args, store)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
  local tree, adapter = (function()
    if args.suite then
      if not args.adapter then
        args.adapter = client:get_adapters()[1]
      end
      return client:get_position(nil, args)
    end
    if args[1] then
      local position_id = lib.files.path.real(args[1]) or args[1]
      return client:get_position(position_id, args)
    end
    local file_path = nio.fn.expand("%:p")
    local row = nio.fn.getpos(".")[2] - 1
    return client:get_nearest(file_path, row, args)
  end)()
  if tree and store then
    last_run = { tree:data().id, vim.tbl_extend("keep", args, { adapter = adapter }) }
  end
  return tree
end

---@class neotest.run.RunArgs : neotest.client.RunTreeArgs
---@field [1] string? Position ID to run
---@field suite boolean Run the entire suite instead of a single position

local function augment_args(tree, args)
  args = type(args) == "string" and { args } or args
  args = args or {}
  local aug = config.run.augment
  if not aug then
    return args
  end
  nio.scheduler()
  return aug(tree, args)
end

--- Run the given position or the nearest position if not given.
--- All arguments are optional
---
--- Run the current file
--- ```vim
---   lua require("neotest").run.run(vim.fn.expand("%"))
--- ```
---
--- Run the nearest test
--- ```vim
---   lua require("neotest").run.run()
--- ```
---
--- Debug the current file with nvim-dap
--- ```vim
---   lua require("neotest").run.run({vim.fn.expand("%"), strategy = "dap"})
--- ```
---@param args string|neotest.run.RunArgs? Position ID to run or args.
function neotest.run.run(args)
  local tree = neotest.run.get_tree_from_args(args, true)
  if not tree then
    lib.notify("No tests found")
    return
  end
  client:run_tree(tree, augment_args(tree, args))
end

neotest.run.run = nio.create(neotest.run.run, 1)

--- Re-run the last position that was run.
--- Arguments are optional
---
--- Run the last position that was run with the same arguments and strategy
--- ```vim
---   lua require("neotest").run.run_last()
--- ```
---
--- Run the last position that was run with the same arguments but debug with
--- nvim-dap
--- ```vim
---   lua require("neotest").run.run_last({ strategy = "dap" })
--- ```
---@param args neotest.run.RunArgs? Argument overrides
function neotest.run.run_last(args)
  args = args or {}
  if not last_run then
    lib.notify("No tests run yet")
    return
  end
  nio.run(function()
    local position_id, last_args = unpack(last_run)
    args = vim.tbl_extend("keep", args, last_args)
    local tree = client:get_position(position_id, args)
    if not tree then
      lib.notify("Last test run no longer exists")
      return
    end
    client:run_tree(tree, augment_args(tree, args))
  end)
end

neotest.run.run_last = nio.create(neotest.run.run_last, 1)

local function get_tree_interactive()
  local running = client:running_positions()
  local elem = nio.ui.select(running, {
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

---@class neotest.run.StopArgs : neotest.client.StopArgs
---@field interactive boolean Select a running position interactively

--- Stop a running process
---
---@param args string|neotest.run.StopArgs? Position ID to stop or args. If
--- args then args[1] should be the position ID.
function neotest.run.stop(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
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
end

neotest.run.stop = nio.create(neotest.run.stop, 1)

---@class neotest.run.AttachArgs : neotest.client.AttachArgs
---@field interactive boolean Select a running position interactively

--- Attach to a running process for the given position.
---
---@param args string|neotest.run.AttachArgs? Position ID to attach to or args. If args then
--- args[1] should be the position ID.
function neotest.run.attach(args)
  args = args or {}
  if type(args) == "string" then
    args = { args }
  end
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
end

neotest.run.attach = nio.create(neotest.run.attach, 1)

--- Get the list of all known adapter IDs.
---@return string[]
---@nodoc
function neotest.run.adapters()
  lib.notify(
    "`neotest.run.adapters` is deprecated, please use `neotest.state.adapter_ids` instead",
    vim.log.levels.WARN
  )
  return require("neotest").state.adapter_ids()
end

--- Get last test position ID and args
---@return string|nil position_id
---@return neotest.run.RunArgs|nil args
function neotest.run.get_last_run()
  if not last_run then
    return nil, nil
  end
  return unpack(last_run)
end

neotest.run = setmetatable(neotest.run, {
  ---@param client_ neotest.Client
  __call = function(_, client_)
    client = client_
    return neotest.run
  end,
})

return neotest.run
