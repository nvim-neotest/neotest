local lib = require("neotest.lib")
-- Source: https://luvit.io/blog/pty-ffi.html

local ffi = require("ffi")
-- Define the bits of the system API we need.
local success, err = pcall(
  ffi.cdef,
  [[
  struct winsize {
      unsigned short ws_row;
      unsigned short ws_col;
      unsigned short ws_xpixel;   /* unused */
      unsigned short ws_ypixel;   /* unused */
  };
  int openpty(int *amaster, int *aslave, char *name,
              void *termp, /* unused so change to void to avoid defining struct */
              const struct winsize *winp);

  ]]
)
if not success then
  lib.notify(err, "error")
end
-- Load the system library that contains the symbol.
local util = ffi.load("util")

local M = {}

---Open a new pty
---@param rows integer
---@param cols integer
---@return integer master file descriptor
---@return integer slave file descriptor
function M.openpty(rows, cols)
  -- Lua doesn't have out-args so we create short arrays of numbers.
  local amaster = ffi.new("int[1]")
  local aslave = ffi.new("int[1]")
  local winp = ffi.new("struct winsize")
  winp.ws_row = rows or os.getenv("LINES") or vim.opt.lines:get()
  winp.ws_col = cols or os.getenv("COLUMNS") or vim.opt.columns:get()
  util.openpty(amaster, aslave, nil, nil, winp)
  -- And later extract the single value that was placed in the array.
  return amaster[0], aslave[0]
end

return M
