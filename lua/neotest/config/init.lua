---@class NeotestConfig
local default_config = {
  adapters = {},
  icons = {
    passed = "✔",
    running = "🗘",
    failed = "✖",
    skipped = "ﰸ",
    unknown = "?",
    collapsed = "─",
    expanded = "╮",
  },
  highlights = {
    passed = "NeotestPassed",
    running = "NeotestRunning",
    failed = "NeotestFailed",
    skipped = "NeotestSkipped",
    test = "NeotestTest",
    namespace = "NeotestNamespace",
    file = "NeotestFile",
    dir = "NeotestDir",
    border = "NeotestBorder",
    indent = "NeotestIndent",
    expand_marker = "NeotestExpandMarker",
    adapter_name = "NeotestAdapterName",
  },
  floating = {
    border = "rounded",
    max_height = 0.6,
    max_width = 0.6,
  },
  strategies = {
    integrated = {
      width = 120,
    },
  },
  summary = {
    follow = true,
    expand_errors = true,
    mappings = {
      expand = { "<CR>" },
      expand_all = { "e" },
      output = { "o" },
      short = { "O" },
      attach = { "a" },
      jumpto = { "i" },
      stop = { "u" },
      run = { "r" },
    },
  },
  output = {
    open_on_run = "short",
  },
}

local user_config = default_config

---@type NeotestConfig
local M = {}

setmetatable(M, {
  __index = function(_, key)
    if key == "setup" then
      return function(config)
        user_config = vim.tbl_deep_extend("force", default_config, config)
      end
    end
    return user_config[key]
  end,
})

return M
