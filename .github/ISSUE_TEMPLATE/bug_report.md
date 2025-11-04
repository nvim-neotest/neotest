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
vim.opt.runtimepath:remove(vim.fn.expand("~/.config/nvim"))
vim.opt.packpath:remove(vim.fn.expand("~/.local/share/nvim/site"))

local lazypath = "/tmp/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neotest/nvim-nio",
    "nvim-treesitter/nvim-treesitter",
    -- Install adapters here
  },
  config = function()
    -- Install any required parsers
    require("nvim-treesitter.configs").setup({
      ensure_installed = {},
    })

    require("neotest").setup({
      -- Add adapters to the list
      adapters = {},
    })
  end,
})
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
1. Wipe the `neotest.log` file in `stdpath("log")` or `stdpath("data")`.
2. Set `log_level = vim.log.levels.DEBUG` in your neotest setup config.
3. Reproduce the issue.
4. Provide the new logs.

**Additional context**
Add any other context about the problem here.
