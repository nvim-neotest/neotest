---@tag neotest.config

vim.cmd([[
  hi default NeotestPassed ctermfg=Green guifg=#96F291
  hi default NeotestFailed ctermfg=Red guifg=#F70067
  hi default NeotestRunning ctermfg=Yellow guifg=#FFEC63
  hi default NeotestSkipped ctermfg=Cyan guifg=#00f1f5
  hi link NeotestTest Normal 
  hi default NeotestNamespace ctermfg=Magenta guifg=#D484FF
  hi default NeotestFile ctermfg=Cyan guifg=#00f1f5
  hi default NeotestDir ctermfg=Cyan guifg=#00f1f5
  hi default NeotestIndent ctermfg=Grey guifg=#8B8B8B
  hi default NeotestExpandMarker ctermfg=Grey guifg=#8094b4
  hi default NeotestAdapterName ctermfg=Red guifg=#F70067
]])

---@class NeotestConfig
---@field adapters NeotestAdapter[]
---@field icons NeotestIconsConfig
---@field highlights NeotestHighlightsConfig
---@field floating NeotestFloatingConfig
---@field strategies NeotestStrategiesConfig
---@field summary NeotestSummaryConfig
---@field output NeotestOutputConfig

---@class NeotestIconsConfig
---@field passed string
---@field running string
---@field failed string
---@field skipped string
---@field unknown string
---@field collapsed string
---@field expanded string

---@class NeotestHighlightsConfig
---@field passed string
---@field running string
---@field failed string
---@field skipped string
---@field test string
---@field namespace string
---@field file string
---@field dir string
---@field border string
---@field indent string
---@field expand_marker string
---@field adapter_name string

---@class NeotestFloatingConfig
---@field border string: Border style
---@field max_height number: Max height of window as proportion of NeoVim window
---@field max_width number: Max width of window as proportion of NeoVim window

---@class NeotestIntegratedStrategyConfig
---@field width integer: Width to pass to the pty runnning commands

---@class NeotestStrategiesConfig
---@field integrated NeotestIntegratedStrategyConfig

---@class NeotestSummaryConfig
---@field enabled boolean
---@field follow boolean: Expand user's current file
---@field expand_errors boolean: Expand all failed positions
---@field mappings NeotestSummaryMappings: Buffer mappings for summary window

---@class NeotestSummaryMappings
---@field expand string | string[]: Expand currently selected position
---@field expand_all string | string[]: Expand all positions under currently selected
---@field output string | string[]: Show output for position
---@field short string | string[]: Show short output for position (if exists)
---@field attach string | string[]: Attach to process for position
---@field jumpto string | string[]: Jump to the selected position
---@field stop string | string[]: Stop selected position
---@field run string | string[]: Run selected position

---@class NeotestOutputConfig
---@field enabled boolean
---@field open_on_run boolean: Open nearest test result after running

---@class NeotestDiagnosticsConfig
---@field enabled boolean

---@class NeotestStatusConfig
---@field enabled boolean

---@type NeotestConfig
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
    enabled = true,
    follow = true,
    expand_errors = true,
    mappings = {
      expand = { "<CR>", "<2-LeftMouse>" },
      expand_all = "e",
      output = "o",
      short = "O",
      attach = "a",
      jumpto = "i",
      stop = "u",
      run = "r",
    },
  },
  output = {
    enabled = true,
    open_on_run = "short",
  },
  diagnostics = {
    enabled = true,
  },
  status = {
    enabled = true,
  },
}

local user_config = default_config

---@type NeotestConfig
local NeotestConfigModule = {}

---@param config NeotestConfig
function NeotestConfigModule.setup(config)
  user_config = vim.tbl_deep_extend("force", default_config, config)
end

function NeotestConfigModule._format_default()
  local lines = { "<pre>", "Default values:" }
  for line in vim.gsplit(vim.inspect(default_config), "\n", true) do
    table.insert(lines, "  " .. line)
  end
  table.insert(lines, "</pre>")
  return lines
end

setmetatable(NeotestConfigModule, {
  __index = function(_, key)
    return user_config[key] or "woops"
  end,
})

return NeotestConfigModule
