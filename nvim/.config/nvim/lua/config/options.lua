-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
-- Set transparency for Neovide
if vim.g.neovide then
  vim.opt.pumblend = 20
  vim.opt.winblend = 20
else
  -- Set no transparency for terminal use
  vim.opt.pumblend = 0
  vim.opt.winblend = 0
end

vim.g.snacks_animate = false
