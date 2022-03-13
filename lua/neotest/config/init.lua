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

---@class neotest.Config
---@field adapters neotest.Adapter[]
---@field icons neotest.Config.icons
---@field highlights neotest.Config.highlights
---@field floating neotest.Config.floating
---@field strategies neotest.Config.strategies
---@field summary neotest.Config.summary
---@field output neotest.Config.output

---@class neotest.Config.icons
---@field passed string
---@field running string
---@field failed string
---@field skipped string
---@field unknown string
---@field collapsed string
---@field expanded string

---@class neotest.Config.highlights
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

---@class neotest.Config.floating
---@field border string: Border style
---@field max_height number: Max height of window as proportion of NeoVim window
---@field max_width number: Max width of window as proportion of NeoVim window

---@class neotest.Config.strategies.integrated
---@field width integer: Width to pass to the pty runnning commands

---@class neotest.Config.strategies
---@field integrated neotest.Config.strategies.integrated

---@class neotest.Config.summary
---@field enabled boolean
---@field follow boolean: Expand user's current file
---@field expand_errors boolean: Expand all failed positions
---@field mappings neotest.Config.summary.mappings: Buffer mappings for summary window

---@class neotest.Config.summary.mappings
---@field expand string | string[]: Expand currently selected position
---@field expand_all string | string[]: Expand all positions under currently selected
---@field output string | string[]: Show output for position
---@field short string | string[]: Show short output for position (if exists)
---@field attach string | string[]: Attach to process for position
---@field jumpto string | string[]: Jump to the selected position
---@field stop string | string[]: Stop selected position
---@field run string | string[]: Run selected position

---@class neotest.Config.output
---@field enabled boolean
---@field open_on_run boolean: Open nearest test result after running

---@class neotest.Config.diagnostic
---@field enabled boolean

---@class neotest.Config.status
---@field enabled boolean

---@type neotest.Config
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
      height = 40,
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
  diagnostic = {
    enabled = true,
  },
  status = {
    enabled = true,
  },
}

local user_config = default_config

---@type neotest.Config
local NeotestConfigModule = {}

---@param config neotest.Config
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
