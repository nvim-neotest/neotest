---
name: Bug report
about: Create a report to help us improve
title: "[BUG]"
labels: ''
assignees: rcarriga

---

**NeoVim Version**
Output of `nvim --version`

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Please provide a minimal `init.lua` to reproduce which can be run as the following:
```sh
nvim --clean -u minimal.lua
```

You can edit the following example file to include your adapters and other required setup.
```lua
-- ignore default config and plugins
vim.opt.runtimepath:remove(vim.fn.expand("~/.config/nvim"))
vim.opt.packpath:remove(vim.fn.expand("~/.local/share/nvim/site"))
vim.opt.termguicolors = true

-- append test directory
local test_dir = "/tmp/nvim-config"
vim.opt.runtimepath:append(vim.fn.expand(test_dir))
vim.opt.packpath:append(vim.fn.expand(test_dir))

-- install packer
local install_path = test_dir .. "/pack/packer/start/packer.nvim"
local install_plugins = false

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.cmd("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
  vim.cmd("packadd packer.nvim")
  install_plugins = true
end

local packer = require("packer")

packer.init({
  package_root = test_dir .. "/pack",
  compile_path = test_dir .. "/plugin/packer_compiled.lua",
})

packer.startup(function(use)
  use("wbthomason/packer.nvim")

  use({
    "nvim-neotest/neotest",
    requires = {
      "vim-test/vim-test",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
    },
    config = function()
      require("neotest").setup({
        adapters = {},
      })
    end,
  })

  if install_plugins then
    packer.sync()
  end
end)

vim.cmd([[
command! NeotestSummary lua require("neotest").summary.toggle()
command! NeotestFile lua require("neotest").run.run(vim.fn.expand("%"))
command! Neotest lua require("neotest").run.run(vim.fn.getcwd())
command! NeotestNearest lua require("neotest").run.run()
command! NeotestDebug lua require("neotest").run.run({ strategy = "dap" })
command! NeotestAttach lua require("neotest").run.attach()
command! NeotestOutput lua require("neotest").output.open()
]])
```

Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

Please provide example test files to reproduce. 

**Expected behavior**
A clear and concise description of what you expected to happen.

**Logs**
Wipe the `neotest.log` file in `stdpath("log")` or `stdpath("data")`, reproduce the issue and provide the new logs.

**Additional context**
Add any other context about the problem here.
