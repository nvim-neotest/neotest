rockspec_format = "3.0"
package = "neotest"
version = "scm-1"

source = {
  url = "git://github.com/nvim-neotest/neotest",
}

description = {
  summary = "An extensible framework for interacting with tests within NeoVim",
  homepage = "https://github.com/nvim-neotest/neotest",
  license = "MIT",
}

dependencies = {
  "lua == 5.1",
  "nvim-nio",
}

test_dependencies = {
  "busted",
  "nlua",
}

test = {
  type = "busted",
}

build = {
  type = "builtin",
  copy_directories = {
    "doc",
  },
}
