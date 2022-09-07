vim.notify = print
vim.opt.swapfile = false
A = function(...)
  print(vim.inspect(...))
end
