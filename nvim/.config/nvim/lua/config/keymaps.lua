-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "

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

-- backspace to switch to previous buffer
map("n", "<bs>", "<C-^>")

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
end, { desc = "LSP refs/defs/type (Trouble, no focus)" })
