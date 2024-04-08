local neotest = {}

---@toc_entry Library
---@text
--- Neotest provides several modules that can be used for common tasks.
--- Some of the modules are quite generic while others are highly tailored to
--- building adapters or consumers.
---
--- The libraries are not meant for general users but are treated as a
--- public API and so will remain mostly stable. The libraries should only be
--- used by accessing require("neotest.lib"). The module structure within the
--- library is considered private and may change without notice.
---@class neotest.lib
neotest.lib = {}

local lazy_require = require("neotest.lib.require")

---@module 'neotest.lib.xml'
---@nodoc
neotest.lib.xml = lazy_require("neotest.lib.xml")

---@nodoc
---@module 'neotest.lib.file'
neotest.lib.files = lazy_require("neotest.lib.file")

---@module 'neotest.lib.func_util'
---@nodoc
neotest.lib.func_util = lazy_require("neotest.lib.func_util")

---@module 'neotest.lib.treesitter''
---@nodoc
neotest.lib.treesitter = lazy_require("neotest.lib.treesitter")

---@nodoc
neotest.lib.notify = function(msg, level, opts)
  vim.schedule(function()
    return vim.notify(
      msg,
      level,
      vim.tbl_extend("keep", opts or {}, {
        title = "Neotest",
        icon = require("neotest.config").icons.notify,
      })
    )
  end)
end

---@module 'neotest.lib.window''
---@nodoc
neotest.lib.persistent_window = lazy_require("neotest.lib.window")

---@module 'neotest.lib.vim_test''
---@nodoc
neotest.lib.vim_test = lazy_require("neotest.lib.vim_test")

---@module 'neotest.lib.ui''
---@nodoc
neotest.lib.ui = lazy_require("neotest.lib.ui")

---@module 'neotest.lib.positions''
---@nodoc
neotest.lib.positions = lazy_require("neotest.lib.positions")

---@module 'neotest.lib.process''
---@nodoc
neotest.lib.process = lazy_require("neotest.lib.process")

---@module 'neotest.lib.subprocess''
---@nodoc
neotest.lib.subprocess = lazy_require("neotest.lib.subprocess")

return neotest.lib
