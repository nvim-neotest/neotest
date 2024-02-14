local nio = require("nio")
local logger = require("neotest.logging")

local child_chan, parent_chan
---@type table<number, nio.control.Future>
local futures = {}
local next_cb_id = 1
local enabled = false
local neotest = { lib = {} }
---@toc_entry Library: Subprocess
---@text
--- Module to interact with a child Neovim instance.
--- This can be used for CPU intensive work like treesitter parsing.
--- All usage should be guarded by checking that the subprocess has been started using the `enabled` function.
---@class neotest.lib.subprocess
neotest.lib.subprocess = {}

local function cleanup()
  if child_chan then
    logger.info("Closing child channel")
    xpcall(function()
      nio.fn.chanclose(child_chan, "rpc")
    end, function(msg)
      logger.error("Failed to close child channel: " .. msg)
    end)
  end
end

---Initialize the subprocess module.
---Do not call this, neotest core will initialize.
---@package
function neotest.lib.subprocess.init()
  logger.info("Starting child process")
  local success, parent_address
  success, parent_address = pcall(nio.fn.serverstart, "localhost:0")
  logger.info("Parent address: " .. parent_address)
  if not success then
    logger.error("Failed to start server: " .. parent_address)
    return
  end
  local cmd = { vim.loop.exepath(), "--embed", "--headless", "-n" }
  logger.info("Starting child process with command: " .. table.concat(cmd, " "))
  success, child_chan = pcall(nio.fn.jobstart, cmd, {
    rpc = true,
    on_exit = function()
      logger.info("Child process exited")
      enabled = false
    end,
  })
  if not success then
    logger.error("Failed to start child process", child_chan)
    return
  end
  xpcall(function()
    local mode = nio.fn.rpcrequest(child_chan, "nvim_get_mode")
    if mode.blocking then
      logger.error("Child process is waiting for input at startup. Aborting.")
      return
    end
    -- Trigger lazy loading of neotest
    nio.fn.rpcrequest(child_chan, "nvim_exec_lua", "return require('neotest') and 0", {})
    nio.fn.rpcrequest(
      child_chan,
      "nvim_exec_lua",
      "return require('neotest.lib').subprocess._set_parent_address(...)",
      { parent_address }
    )
    -- Load dependencies
    if pcall(require, "nvim-treesitter") then
      nio.fn.rpcrequest(child_chan, "nvim_exec_lua", "require('nvim-treesitter')", {})
    end
    nio.fn.rpcrequest(child_chan, "nvim_exec_lua", "require('plenary')", {})
    enabled = true
    nio.api.nvim_create_autocmd("VimLeavePre", { callback = cleanup })
  end, function(msg)
    logger.error("Failed to initialize child process", debug.traceback(msg, 2))
    cleanup()
    child_chan = nil
  end)
end

---@private
function neotest.lib.subprocess._set_parent_address(parent_address)
  _G._NEOTEST_IS_CHILD = true
  parent_chan = vim.fn.sockconnect("tcp", parent_address, { rpc = true })
  logger.info("Connected to parent instance")
end

---@private
function neotest.lib.subprocess._register_result(callback_id, res, err)
  logger.debug("Result registed for callback", callback_id)
  local future = futures[callback_id]
  futures[callback_id] = nil
  if err then
    future.set_error(err)
  else
    future.set(res)
  end
end

local function get_chan()
  if neotest.lib.subprocess.is_child() then
    return parent_chan
  else
    return child_chan
  end
end

---@async
--- Wrapper around vim.fn.rpcrequest that will automatically select the channel for the child or parent process,
--- depending on if the current instance is the child or parent.
--- See `:help rpcrequest` for more information.
--- @param method string
--- @param ... any
function neotest.lib.subprocess.request(method, ...)
  nio.fn.rpcrequest(get_chan(), method, ...)
end

---@async
---Wrapper around vim.fn.rpcnotify that will automatically select the channel for the child or parent process,
---depending on if the current instance is the child or parent.
---See `:help rpcnotify` for more information.
--- @param method string
--- @param ... any
function neotest.lib.subprocess.notify(method, ...)
  nio.fn.rpcnotify(get_chan(), method, ...)
end

---@async
--- Call a lua function in the other process with the given argument list, returning the result.
--- The function will be called in async context.
---@param func string A globally accessible function in the other process. e.g. `"require('neotest.lib').files.read"`
---@param args? any[] Arguments to pass to the function
---@return any result Value returned by remote call
function neotest.lib.subprocess.call(func, args)
  local result_future = nio.control.future()
  local cb_id = next_cb_id
  next_cb_id = next_cb_id + 1
  futures[cb_id] = result_future
  logger.debug("Waiting for result", cb_id)
  local _, err = pcall(
    neotest.lib.subprocess.request,
    "nvim_exec_lua",
    "return require('neotest.lib.subprocess')._remote_call(" .. func .. ", ...)",
    { cb_id, args or {} }
  )
  assert(not err, ("Invalid subprocess call: %s"):format(err))
  return result_future.wait()
end

---@private
function neotest.lib.subprocess._remote_call(func, cb_id, args)
  logger.info("Received remote call", cb_id, func)
  nio.run(function()
    xpcall(function()
      local res = func(unpack(args))
      neotest.lib.subprocess.notify(
        "nvim_exec_lua",
        "return require('neotest.lib.subprocess')._register_result(...)",
        { cb_id, res }
      )
    end, function(msg)
      local err = debug.traceback(msg, 2)
      logger.warn("Error in remote call", err)
      neotest.lib.subprocess.notify(
        "nvim_exec_lua",
        "return require('neotest.lib.subprocess')._register_result(...)",
        { cb_id, nil, err }
      )
    end)
  end)
end

--- Check if the subprocess has been initialized and is working
---@return boolean
function neotest.lib.subprocess.enabled()
  return enabled
end

--- Check if the current neovim instance is the child or parent process
---@return boolean
function neotest.lib.subprocess.is_child()
  return parent_chan ~= nil
end

return neotest.lib.subprocess
