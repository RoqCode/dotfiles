-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "
local bs = "<BS>" -- secondary leader

local map = vim.keymap.set
-- local del = vim.keymap.del

-- add empty line on enter
map("n", "<CR>", "o<ESC>")
map("n", "<S-CR>", "O<ESC>")

-- redo with U
map("n", "U", "<C-r>", { noremap = true, silent = true })

-- scroll down and center view
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- delete and change without buffer
map("v", "d", '"_d')
map("v", "c", '"_c')
map("n", "<S-BS>", '"_dd', { noremap = true, silent = true })
map("x", "<leader>p", '"_dP', { noremap = true, silent = true })

-- center on next selection
map("n", "n", "nzz", { noremap = true, silent = true })
map("n", "N", "Nzz", { noremap = true, silent = true })

-- toggle precognition hints
map("n", "<leader>p", ":Precognition toggle<CR>", { noremap = true, silent = true })

-- scroll by 15 lines
map("n", ")", "15jzz")
map("n", "}", "15kzz")

-- scroll by one line and move curser by one line
map("n", "<C-e>", "<C-e>j")
map("n", "<C-y>", "<C-y>k")

-- Fensterbreite
map("n", "<C-Left>", "<cmd>vertical resize -3<cr>", { desc = "Schmaler" })
map("n", "<C-Right>", "<cmd>vertical resize +3<cr>", { desc = "Breiter" })

-- Fensterhöhe
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Höher" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Niedriger" })

-- Fenster ausgleichen
map("n", "<leader>=", "<C-w>=", { desc = "Fenster ausgleichen" })

-- keymap (z. B. in lua/config/keymaps.lua)
map("n", "<leader>cS", function()
  require("trouble").toggle({
    source = "lsp",
    mode = "lsp",
    focus = true,
  })
end, { desc = "LSP refs/defs/type" })

-- Navigation
vim.keymap.set("n", bs .. "s", "<cmd>AerialNavToggle<cr>", { desc = "Aerial Nav" })
vim.keymap.set("n", bs .. "S", function()
  require("trouble").toggle({
    source = "lsp",
    mode = "lsp",
    focus = true,
  })
end, { desc = "Trouble LSP (refs/defs/types)" })
vim.keymap.set("n", bs .. "r", "<cmd>FzfLua live_grep_resume<cr>", { desc = "Resume Grep" })

-- Diagnostics
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
vim.keymap.set("n", bs .. "d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", bs .. "D", function()
  require("trouble").toggle({
    source = "diagnostics",
    mode = "diagnostics",
    focus = true,
  })
end, { desc = "Trouble Diagnostics" })

-- Quickfix
vim.keymap.set("n", bs .. "q", "<cmd>copen<cr>", { desc = "Quickfix toggle" })
vim.keymap.set("n", bs .. "n", "<cmd>cnext<cr>", { desc = "Quickfix Next" })
vim.keymap.set("n", bs .. "p", "<cmd>cprev<cr>", { desc = "Quickfix Prev" })

-- LSP Goodies
vim.keymap.set("n", bs .. "c", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Extras
vim.keymap.set("n", bs .. "t", "<cmd>Trouble todo toggle<cr>", { desc = "Todo Comments" })
vim.keymap.set("n", bs .. "o", "<cmd>only<cr>", { desc = "Only window" })

-- UndoTree
vim.keymap.set("n", bs .. "u", function()
  require("undotree").toggle()
end, { desc = "Undo Tree" })

-- Debug / Logging
vim.keymap.set("n", bs .. "l", function()
  require("refactoring").debug.printf({ below = false })
end, { desc = "Debug Print" })
vim.keymap.set({ "n", "x" }, bs .. "L", function()
  require("refactoring").debug.print_var({ normal = true })
end, { desc = "Debug Print Variable" })
vim.keymap.set("n", bs .. "x", function()
  require("refactoring").debug.cleanup({})
end, { desc = "Debug Cleanup" })
