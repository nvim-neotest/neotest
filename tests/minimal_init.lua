-- Minimal init for headless mini.test runs (see scripts/test).
--
-- Dependency resolution, in order:
--  - CI clones deps into ~/.local/share/nvim/site/pack/vendor/start/, which
--    Neovim adds to the runtimepath automatically.
--  - Local runs can point at a deps directory with $NEOTEST_TEST_DEPS
--    (containing mini.test/, nvim-nio/, nvim-treesitter/).
--  - The lazy.nvim-style $XDG_DATA_HOME/lazy/ paths are kept for developers.

local lazypath = vim.fn.stdpath("data") .. "/lazy"
local deps = vim.env.NEOTEST_TEST_DEPS

vim.notify = print
vim.opt.rtp:append(".")
-- mini.test comes from the standalone nvim-mini/mini.test repo in CI; the
-- extra "mini.nvim" entry is a no-op fallback for developers who have the
-- full library in their lazy dir (both expose lua/mini/test.lua).
for _, name in ipairs({ "mini.test", "mini.nvim", "nvim-treesitter", "nvim-nio" }) do
  if deps and deps ~= "" then
    vim.opt.rtp:append(deps .. "/" .. name)
  end
  vim.opt.rtp:append(lazypath .. "/" .. name)
end

local home = os.getenv("HOME")
vim.opt.rtp:append(home .. "/Dev/nvim-nio")

vim.opt.swapfile = false

-- Allow specs to require test helpers as `tests.assertions` etc.
package.path = "./?.lua;" .. vim.fn.getcwd() .. "/?.lua;" .. package.path

require("mini.test").setup({
  collect = {
    emulate_busted = true,
    find_files = function()
      -- `*_disabled.lua` files (e.g. init_spec_disabled.lua) do not match the
      -- `*_spec.lua` glob and are intentionally excluded.
      return vim.fn.globpath("tests/unit", "**/*_spec.lua", true, true)
    end,
  },
})

A = function(...)
  print(vim.inspect(...))
end
