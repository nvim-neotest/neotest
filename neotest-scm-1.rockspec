local _MODREV, _SPECREV = 'scm', '-1'

rockspec_format = "3.0"
package = 'neotest'
version = _MODREV .. _SPECREV

description = {
  summary = "A framework for interacting with tests within NeoVim.",
  detailed = [[
    See :h neotest for details on neotest is designed and how to interact with it programmatically.
  ]],
  homepage = 'https://github.com/nvim-neotest/neotest',
  license = 'MIT',
  labels = { 'neovim', 'tree-sitter', 'test' }
}

dependencies = {
  'lua == 5.1',
  'plenary.nvim',
}

source = {
  url = 'https://github.com/nvim-neotest/neotest/archive/v' .. _MODREV .. '.zip',
  dir = 'neotest-' .. _MODREV,
}

if _MODREV == 'scm' then
  source = {
    url = 'git://github.com/nvim-neotest/neotest',
  }
end

build = {
  type = 'builtin',
  copy_directories = {
    'doc'
  }
}
