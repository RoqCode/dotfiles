local uname = (vim.loop.os_uname() or {}).sysname
local os

if uname == "Darwin" then
  os = "mac"
elseif uname == "Linux" then
  os = "linux"
else
  os = "unknown"
end

vim.g.dot_os = os

pcall(require, "config.platform." .. os)
