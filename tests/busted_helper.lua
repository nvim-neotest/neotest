local root = vim.fn.getcwd()
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")
vim.opt.rtp:append(root)
vim.o.swapfile = false
vim.notify = print
-- subprocess children inherit env; nvim honors LUA_PATH — this is how the
-- child nvim resolves neotest + nio under luarocks
vim.env.LUA_PATH = package.path
vim.env.LUA_CPATH = package.cpath
-- nio.tests async timeout (legacy var name, still read by nvim-nio)
vim.env.PLENARY_TEST_TIMEOUT = vim.env.PLENARY_TEST_TIMEOUT or "10000"
A = function(...)
  print(vim.inspect(...))
end
