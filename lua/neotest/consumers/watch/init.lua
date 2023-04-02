local lib = require("neotest.lib")
local nio = require("nio")
local Watcher = require("neotest.consumers.watch.watcher")

local watchers = {}

local neotest = {}

---@toc_entry Watch Consumer
---@text
--- Allows watching tests and re-running them whenever related files are
--- changed. When watching a directory, all files are run in separate processes.
--- Otherwise the tests are run in the same process (if allowed by the adapter).
---
--- Related files are determined through an LSP client through a "best effort"
--- which means there are cases where a file may not be determined as related
--- despite it having an effect on a test.
---@class neotest.consumers.watch
neotest.watch = {}

--- Watch a position and run it whenever related files are changed.
--- Arguments are the same as the `neotest.run.run`, which allows
--- for custom runner arguments, env vars, strategy etc. If a position is
--- already being watched, the existing watcher will be stopped.
---@param args? neotest.run.RunArgs|string
function neotest.watch.watch(args)
  nio.run(function()
    local watcher = Watcher(args)
    if not watcher then
      return
    end
    if watchers[watcher.watching] then
      neotest.watch.stop(watcher.watching)
    end
    watchers[watcher.watching] = watcher
  end)
end

--- Stop watching a position. If no position is provided, all watched positions are stopped.
function neotest.watch.stop(pos_id)
  if not pos_id then
    for watched in pairs(watchers) do
      neotest.watch.stop(watched)
    end
    return
  end

  if not watchers[pos_id] then
    lib.notify(("%s is not being watched"):format(pos_id), vim.log.levels.WARN)
    return
  end

  watchers[pos_id]:stop_watch()
  watchers[pos_id] = nil
end

--- Check if a position is being watched.
---@param position_id string
---@return boolean
function neotest.watch.is_watching(position_id)
  return watchers[position_id] ~= nil
end

neotest.watch = setmetatable(neotest.watch, {
  __call = function()
    return neotest.watch
  end,
})

return neotest.watch
