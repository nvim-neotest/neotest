local lazypath = vim.fn.stdpath("data") .. "/lazy"
vim.notify = print
vim.opt.rtp:append(".")
vim.opt.rtp:append(lazypath .. "/plenary.nvim")
vim.opt.rtp:append(lazypath .. "/nvim-dap")
vim.opt.rtp:append(lazypath .. "/nvim-treesitter")
vim.opt.swapfile = false
A = function(...)
  print(vim.inspect(...))
end
