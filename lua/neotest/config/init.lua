return {
  icons = {
    passed = "✔",
    running = "🗘",
    failed = "✖",
    skipped = "ﰸ",
    unknown = "?",
    collapsed = "▸",
    expanded = "▾",
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
