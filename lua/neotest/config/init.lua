---@tag neotest.config
---@toc_entry Configuration Options

local function define_highlights()
  vim.cmd([[
  hi default NeotestPassed ctermfg=Green guifg=#96F291
  hi default NeotestFailed ctermfg=Red guifg=#F70067
  hi default NeotestRunning ctermfg=Yellow guifg=#FFEC63
  hi default NeotestSkipped ctermfg=Cyan guifg=#00f1f5
  hi default link NeotestTest Normal
  hi default NeotestNamespace ctermfg=Magenta guifg=#D484FF
  hi default NeotestFocused gui=bold,underline cterm=bold,underline
  hi default NeotestFile ctermfg=Cyan guifg=#00f1f5
  hi default NeotestDir ctermfg=Cyan guifg=#00f1f5
  hi default NeotestIndent ctermfg=Grey guifg=#8B8B8B
  hi default NeotestExpandMarker ctermfg=Grey guifg=#8094b4
  hi default NeotestAdapterName ctermfg=Red guifg=#F70067
  hi default NeotestWinSelect ctermfg=Cyan guifg=#00f1f5 gui=bold
  hi default NeotestMarked ctermfg=Brown guifg=#F79000 gui=bold
  hi default NeotestTarget ctermfg=Red guifg=#F70067
  hi default NeotestWatching ctermfg=Yellow guifg=#FFEC63
  hi default link NeotestUnknown Normal
]])
end

local augroup = vim.api.nvim_create_augroup("NeotestColorSchemeRefresh", {})
vim.api.nvim_create_autocmd("ColorScheme", { callback = define_highlights, group = augroup })
define_highlights()

local js_watch_query = [[
  ;query
  ;Captures named imports
  (import_specifier name: (identifier) @symbol)
  ;Captures default import
  (import_clause (identifier) @symbol)
  ;Capture require statements
  (variable_declarator 
  name: (identifier) @symbol
  value: (call_expression (identifier) @function  (#eq? @function "require")))
  ;Capture namespace imports
  (namespace_import (identifier) @symbol)
]]

---@class neotest.CoreConfig
---@field adapters neotest.Adapter[]
---@field discovery neotest.Config.discovery
---@field running neotest.Config.running
---@field default_strategy string|function

---@class neotest.Config : neotest.CoreConfig
---@field log_level number Minimum log levels, one of vim.log.levels
---@field consumers table<string, neotest.Consumer>
---@field icons table Icons used throughout the UI. Defaults use VSCode's codicons
---@field highlights table<string, string>
---@field floating neotest.Config.floating
---@field strategies neotest.Config.strategies
---@field run neotest.Config.run
---@field summary neotest.Config.summary
---@field output neotest.Config.output
---@field output_panel neotest.Config.output_panel
---@field quickfix neotest.Config.quickfix
---@field status neotest.Config.status
---@field state neotest.Config.state
---@field watch neotest.Config.watch
---@field diagnostic neotest.Config.diagnostic
---@field projects table<string, neotest.CoreConfig> Project specific settings, keys
--- are project root directories (e.g "~/Dev/my_project")

---@class neotest.Config.discovery
---@field enabled boolean
---@field concurrent integer Number of workers to parse files concurrently. 0 automatically assigns number based on CPU. Set to 1 if experiencing lag.
---@field filter_dir nil | fun(name: string, rel_path: string, root: string): boolean A function to filter directories when searching for test files. Receives the name, path relative to project root and project root path

---@class neotest.Config.running
---@field concurrent boolean Run tests concurrently when an adapter provides multiple commands to run

---@alias neotest.Consumer fun(client: neotest.Client): table

---@class neotest.Config.floating
---@field border? string Border style
---@field max_height number Max height of window as proportion of NeoVim window
---@field max_width number Max width of window as proportion of NeoVim window
---@field options table Window local options to set on floating windows (e.g. winblend)

---@class neotest.Config.strategies.integrated
---@field width integer Width to pass to the pty runnning commands

---@class neotest.Config.strategies
---@field integrated neotest.Config.strategies.integrated

---@class neotest.Config.run
---@field enabled boolean
---@field augment? fun(tree: neotest.Tree, arg: neotest.run.RunArgs):neotest.run.RunArgs A function to augment the arguments any tests being run

---@class neotest.Config.summary
---@field enabled boolean
---@field animated boolean Enable/disable animation of icons
---@field follow boolean Expand user's current file
---@field expand_errors boolean Expand all failed positions
---@field mappings neotest.Config.summary.mappings Buffer mappings for summary window
---@field open string | fun(): integer A command or function to open a window for the summary
---@field count boolean Display number of tests found beside the adapter name

---@class neotest.Config.summary.mappings
---@field expand string|string[] Expand currently selected position
---@field expand_all string|string[] Expand all positions under currently selected
---@field output string|string[] Show output for position
---@field short string|string[] Show short output for position (if exists)
---@field attach string|string[] Attach to process for position
---@field jumpto string|string[] Jump to the selected position
---@field stop string|string[] Stop selected position
---@field run string|string[] Run selected position
---@field debug string|string[] Debug selected position
---@field mark string|string[] Mark the selected position
---@field run_marked string|string[] Run the marked positions for selected suite.
---@field debug_marked string|string[] Debug the marked positions for selected suite.
---@field clear_marked string|string[] Clear the marked positions for selected suite.
---@field target string|string[] Target a position to be the only shown position for its adapter
---@field clear_target string|string[] Clear the target position for the selected adapter
---@field next_failed string|string[] Jump to the next failed position
---@field prev_failed string|string[] Jump to the previous failed position
---@field watch string|string[] Toggle watching for changes

---@class neotest.Config.output
---@field enabled boolean
---@field open_on_run string|boolean Open nearest test result after running

---@class neotest.Config.state
---@field enabled boolean

---@class neotest.Config.output_panel
---@field enabled boolean
---@field open string|fun():integer A command or function to open a window for the output panel

---@class neotest.Config.quickfix
---@field enabled boolean
---@field open boolean|function Set to true to open quickfix on startup, or a function to be
--- called when the quickfix results are set

---@class neotest.Config.diagnostic
---@field enabled boolean
---@field severity number Diagnostic severity, one of vim.diagnostic.severity

---@class neotest.Config.status
---@field enabled boolean
---@field virtual_text boolean Display status using virtual text
---@field signs boolean Display status using signs

---@class neotest.Config.watch
---@field enabled boolean
---@field symbol_queries table<string, string|fun(root, content: string, path: string):integer[][]> Treesitter queries or functions to capture symbols that are used for querying the LSP server for defintions to link files. If it is a function then the return value should be a list of node ranges.
---@field filter_path? fun(path: string, root: string): boolean Returns whether the watcher should inspect a path for dependencies. Default ignores paths not under root or common package manager directories.

---@private
---@type neotest.Config
local default_config = {
  log_level = vim.log.levels.WARN,
  adapters = {},
  discovery = {
    enabled = true,
    concurrent = 0,
    filter_dir = nil,
  },
  running = {
    concurrent = true,
  },
  consumers = {},
  icons = {
    -- Ascii:
    -- { "/", "|", "\\", "-", "/", "|", "\\", "-"},
    -- Unicode:
    -- { "", "🞅", "🞈", "🞉", "", "", "🞉", "🞈", "🞅", "", },
    -- {"◴" ,"◷" ,"◶", "◵"},
    -- {"◢", "◣", "◤", "◥"},
    -- {"◐", "◓", "◑", "◒"},
    -- {"◰", "◳", "◲", "◱"},
    -- {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
    -- {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
    -- {"⠋", "⠙", "⠚", "⠞", "⠖", "⠦", "⠴", "⠲", "⠳", "⠓"},
    -- {"⠄", "⠆", "⠇", "⠋", "⠙", "⠸", "⠰", "⠠", "⠰", "⠸", "⠙", "⠋", "⠇", "⠆"},
    -- { "⠋", "⠙", "⠚", "⠒", "⠂", "⠂", "⠒", "⠲", "⠴", "⠦", "⠖", "⠒", "⠐", "⠐", "⠒", "⠓", "⠋" },
    running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
    passed = "",
    running = "",
    failed = "",
    skipped = "",
    unknown = "",
    non_collapsible = "─",
    collapsed = "─",
    expanded = "╮",
    child_prefix = "├",
    final_child_prefix = "╰",
    child_indent = "│",
    final_child_indent = " ",
    watching = "",
    test = "",
    notify = "",
  },
  highlights = {
    passed = "NeotestPassed",
    running = "NeotestRunning",
    failed = "NeotestFailed",
    skipped = "NeotestSkipped",
    test = "NeotestTest",
    namespace = "NeotestNamespace",
    focused = "NeotestFocused",
    file = "NeotestFile",
    dir = "NeotestDir",
    border = "NeotestBorder",
    indent = "NeotestIndent",
    expand_marker = "NeotestExpandMarker",
    adapter_name = "NeotestAdapterName",
    select_win = "NeotestWinSelect",
    marked = "NeotestMarked",
    target = "NeotestTarget",
    unknown = "NeotestUnknown",
    watching = "NeotestWatching",
  },
  floating = {
    border = nil,
    max_height = 0.6,
    max_width = 0.6,
    options = {},
  },
  default_strategy = "integrated",
  strategies = {
    integrated = {
      width = 120,
      height = 40,
    },
  },
  summary = {
    enabled = true,
    count = true,
    animated = true,
    follow = true,
    expand_errors = true,
    open = "botright vsplit | vertical resize 50",
    mappings = {
      expand = { "<CR>", "<2-LeftMouse>" },
      expand_all = "e",
      output = "o",
      short = "O",
      attach = "a",
      jumpto = "i",
      stop = "u",
      run = "r",
      debug = "d",
      mark = "m",
      run_marked = "R",
      debug_marked = "D",
      clear_marked = "M",
      target = "t",
      clear_target = "T",
      next_failed = "J",
      prev_failed = "K",
      watch = "w",
      help = "?",
    },
  },
  benchmark = {
    enabled = true,
  },
  output = {
    enabled = true,
    open_on_run = "short",
  },
  output_panel = {
    enabled = true,
    open = "botright split | resize 15",
  },
  diagnostic = {
    enabled = true,
    severity = vim.diagnostic.severity.ERROR,
  },
  status = {
    enabled = true,
    virtual_text = false,
    signs = true,
  },
  run = {
    enabled = true,
  },
  jump = {
    enabled = true,
  },
  quickfix = {
    enabled = true,
    open = false,
  },
  state = {
    enabled = true,
  },
  watch = {
    enabled = true,
    symbol_queries = {
      typescript = js_watch_query,
      javascript = js_watch_query,
      tsx = js_watch_query,
      python = [[
        ;query
        ;Captures imports and modules they're imported from
        (import_from_statement (_ (identifier) @symbol))
        (import_statement (_ (identifier) @symbol))
      ]],
      go = [[
        ;query
        ;Captures imported types
        (qualified_type name: (type_identifier) @symbol)
        ;Captures package-local and built-in types
        (type_identifier)@symbol
        ;Captures imported function calls and variables/constants
        (selector_expression field: (field_identifier) @symbol)
        ;Captures package-local functions calls
        (call_expression function: (identifier) @symbol)
      ]],
      lua = [[
        ;query
        ;Captures module names in require calls
        (function_call
          name: ((identifier) @function (#eq? @function "require"))
          arguments: (arguments (string) @symbol))
      ]],
      elixir = function(root, content)
        local lib = require("neotest.lib")
        local query = lib.treesitter.normalise_query(
          "elixir",
          [[;; query
            (call (identifier) @_func_name
              (arguments (alias) @symbol)
              (#match? @_func_name "^(alias|require|import|use)")
              (#gsub! @symbol ".*%.(.*)" "%1")
            )
          ]]
        )
        local symbols = {}
        for _, match, metadata in query:iter_matches(root, content, nil, nil, { all = false }) do
          for id, node in pairs(match) do
            local name = query.captures[id]

            if name == "symbol" then
              local start_row, start_col, end_row, end_col = node:range()
              if metadata[id] ~= nil then
                local real_symbol_length = string.len(metadata[id]["text"])
                start_col = end_col - real_symbol_length
              end

              symbols[#symbols + 1] = { start_row, start_col, end_row, end_col }
            end
          end
        end
        return symbols
      end,
      ruby = [[
        ;query
        ;rspec - class name
        (call
          method: (identifier) @_ (#match? @_ "^(describe|context)")
          arguments: (argument_list (constant) @symbol )
        )

        ;rspec - namespaced class name
        (call
          method: (identifier)
          arguments: (argument_list
            (scope_resolution
              name: (constant) @symbol))
        )
      ]],
      rust = [[
        ;query
        ;submodule import
        (mod_item
          name: (identifier) @symbol)
        ;single import
        (use_declaration
          argument: (scoped_identifier
            name: (identifier) @symbol))
        ;import list
        (use_declaration
          argument: (scoped_use_list
            list: (use_list
                [(scoped_identifier
                   path: (identifier)
                   name: (identifier) @symbol)
                 ((identifier) @symbol)])))
        ;wildcard import
        (use_declaration
          argument: (scoped_use_list
            path: (identifier)
            [(use_list
              [(scoped_identifier
                path: (identifier)
                name: (identifier) @symbol)
                ((identifier) @symbol)
              ])]))
      ]],
      swift = [[
        ;query
        ;import
        (simple_identifier) @symbol
      ]],
      haskell = [[
        ;query
        ;explicit import
        (import_name (variable) @symbol)
        ;symbols that may be imported implicitly
        ((type) @symbol)
        (qualified (name) @symbol)
        (apply (variable) @symbol)
        ((constructor) @symbol)
        ((operator) @symbol)
      ]],
      java = [[
        ;query
        ;captures imported classes
        (import_declaration
            (scoped_identifier name: ((identifier) @symbol))
        )
      ]],
    },
    filter_path = nil,
  },
  projects = {},
}

local user_config = default_config

---@private
---@type neotest.Config
local NeotestConfigModule = {}

local convert_concurrent = function(val)
  if val == 0 or val == true then
    -- Hack for Android devices, where cpu_info() returns nil
    local cpu_info = vim.loop.cpu_info() or {}
    return #cpu_info + 4
  end
  if val == false then
    return 1
  end
  assert(type(val) == "number", "concurrent must be a boolean or a number")
  return val
end

---@param config neotest.Config
---@private
function NeotestConfigModule.setup(config)
  ---@type neotest.Config
  user_config = vim.tbl_deep_extend("force", default_config, config)
  --- Avoid mutating default for docgen
  user_config.discovery = vim.tbl_deep_extend(
    "force",
    user_config.discovery,
    { concurrent = convert_concurrent(user_config.discovery.concurrent) }
  )

  user_config.projects = setmetatable({}, {
    __index = function()
      return user_config
    end,
  })
  for project_root, project_config in pairs(config.projects or {}) do
    NeotestConfigModule.setup_project(project_root, project_config)
  end

  local logger = require("neotest.logging")
  logger:set_level(user_config.log_level)
  logger.info("Configuration complete")
  logger.debug("User config", user_config)
end

function NeotestConfigModule.setup_project(project_root, config)
  local path = vim.fn.fnamemodify(project_root, ":p")
  path = path:sub(1, #path - 1) -- Trailing slash
  user_config.projects[path] = vim.tbl_deep_extend("keep", config, {
    adapters = user_config.adapters,
    discovery = user_config.discovery,
    running = user_config.running,
    default_strategy = user_config.default_strategy,
  })
  user_config.projects[path].discovery.concurrent =
    convert_concurrent(user_config.projects[path].discovery.concurrent)
  local logger = require("neotest.logging")
  logger.info("Project", path, "configuration complete")
  logger.debug("Project config", user_config.projects[path])
end

function NeotestConfigModule._format_default()
  local lines = { "Default values:", ">lua" }
  for line in vim.gsplit(vim.inspect(default_config), "\n", true) do
    table.insert(lines, "  " .. line)
  end
  table.insert(lines, "<")
  return lines
end

setmetatable(NeotestConfigModule, {
  __index = function(_, key)
    return user_config[key]
  end,
})

return NeotestConfigModule
