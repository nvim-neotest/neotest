local async = require("neotest.async")
local logger = require("neotest.logging")

local child_chan, parent_chan
local callbacks = {}
local next_cb_id = 1
local enabled = false

local M = {}

local function cleanup()
  if child_chan then
    logger.info("Closing child channel")
    xpcall(function()
      async.fn.chanclose(child_chan, "rpc")
    end, function(msg)
      logger.error("Failed to close child channel: " .. msg)
    end)
  end
end

---Initialize the subprocess module.
---Do not call this, neotest core will initialize.
function M.init()
  logger.info("Starting child process")
  local parent_address = async.fn.serverstart()
  local success
  local cmd = { vim.loop.exepath(), "--embed", "--headless" }
  logger.info("Starting child process with command: " .. table.concat(cmd, " "))
  success, child_chan = pcall(async.fn.jobstart, cmd, {
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
    local mode = async.fn.rpcrequest(child_chan, "nvim_get_mode")
    if mode.blocking then
      logger.error("Child process is waiting for input at startup. Aborting.")
    end
    -- Trigger lazy loading of neotest
    async.fn.rpcrequest(child_chan, "nvim_exec_lua", "return require('neotest') and 0", {})
    async.fn.rpcrequest(
      child_chan,
      "nvim_exec_lua",
      "return require('neotest.lib').subprocess._set_parent_address(...)",
      { parent_address }
    )
    enabled = true
    async.api.nvim_create_autocmd("VimLeavePre", { callback = cleanup })
  end, function(msg)
    logger.error("Failed to initialize child process", debug.traceback(msg, 2))
    cleanup()
    child_chan = nil
  end)
end

function M._set_parent_address(parent_address)
  _G._NEOTEST_IS_CHILD = true
  parent_chan = vim.fn.sockconnect("pipe", parent_address, { rpc = true })
  logger.info("Connected to parent instance")
end

function M._register_result(callback_id, res, err)
  logger.debug("Result registed for callback", callback_id)
  local cb = callbacks[callback_id]
  callbacks[callback_id] = nil
  cb(res, err)
end

local function get_chan()
  if M.is_child() then
    return parent_chan
  else
    return child_chan
  end
end

---@async
---Wrapper around vim.fn.rpcrequest that will automatically select the channel for the child or parent process,
---depending on if the current instance is the child or parent.
---See `:help rpcrequest` for more information.
function M.request(method, ...)
  async.fn.rpcrequest(get_chan(), method, ...)
end

---@async
---Wrapper around vim.fn.rpcnotify that will automatically select the channel for the child or parent process,
---depending on if the current instance is the child or parent.
---See `:help rpcnotify` for more information.
function M.notify(method, ...)
  async.fn.rpcnotify(get_chan(), method, ...)
end

---@async
---Call a lua function in the other process with the given argument list, returning the result.
---The function will be called in async context.
---@param func string A globally accessible function in the other process. e.g. `"require('neotest.lib').files.read"`
---@param args? any[] Arguments to pass to the function
---@return any, string?: Result or error message if call failed
function M.call(func, args)
  local send_result, await_result = async.control.channel.oneshot()
  local cb_id = next_cb_id
  next_cb_id = next_cb_id + 1
  callbacks[cb_id] = send_result
  logger.debug("Waiting for result", cb_id)
  M.notify(
    "nvim_exec_lua",
    "return require('neotest.lib.subprocess')._remote_call(" .. func .. ", ...)",
    { cb_id, args or {} }
  )
  return await_result()
end

function M._remote_call(func, cb_id, args)
  logger.debug("Received remote call", cb_id, func)
  async.run(function()
    xpcall(function()
      local res = func(unpack(args))
      M.notify(
        "nvim_exec_lua",
        "return require('neotest.lib.subprocess')._register_result(...)",
        { cb_id, res }
      )
    end, function(msg)
      local err = debug.traceback(msg, 2)
      logger.warn("Error in remote call", err)
      M.notify(
        "nvim_exec_lua",
        "return require('neotest.lib.subprocess')._register_result(...)",
        { cb_id, nil, err }
      )
    end)
  end)
end

function M.enabled()
  return enabled
end

function M.is_child()
  return parent_chan ~= nil
end

return M
