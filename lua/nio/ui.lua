local tasks = require("nio.tasks")

local nio = {}

---@text
--- Async versions of vim.ui functions.
---@class nio.ui
nio.ui = {}

---@async
---@param args nio.ui.InputArgs
function nio.ui.input(args) end

---@class nio.ui.InputArgs
---@field prompt string|nil Text of the prompt
---@field default string|nil Default reply to the input
---@field completion string|nil Specifies type of completion supported for input. Supported types are the same that can be supplied to a user-defined command using the "-complete=" argument. See |:command-completion|
---@field highlight function Function that will be used for highlighting user inputs.

---@async
---@param items any[]
---@param args nio.ui.SelectArgs
function nio.ui.select(items, args) end

---@class nio.ui.SelectArgs
---@field prompt string|nil Text of the prompt. Defaults to `Select one of:`
---@field format_item function|nil Function to format an individual item from `items`. Defaults to `tostring`.
---@field kind string|nil Arbitrary hint string indicating the item shape. Plugins reimplementing `vim.ui.select` may wish to use this to infer the structure or semantics of `items`, or the context in which select() was called.

nio.ui = {
  ---@nodoc
  select = tasks.wrap(vim.ui.select, 3),
  ---@nodoc
  input = tasks.wrap(vim.ui.input, 2),
}

return nio.ui
