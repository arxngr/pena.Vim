local utils = require("core.utils")
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

-- General
keymap("n", "c", utils.open_config, { desc = "Open AnVim config" })
keymap("n", "d", '"_d', opts)
keymap("x", "d", '"_d', opts)
keymap("x", "<leader>p", '"_dP', opts)
keymap("n", "<C-c>", '"+y', opts)
keymap("v", "<C-c>", '"+y', opts)
keymap("n", "<C-v>", '"+p', opts)
keymap("v", "<C-v>", '"+p', opts)

-- Remap example (intentionally allows remapping)
keymap("n", "<C-d>", "mciw*<Cmd>nohl<CR>", { remap = true })

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize windows with arrows
keymap("n", "<Up>", ":resize -2<CR>", opts)
keymap("n", "<Down>", ":resize +2<CR>", opts)
keymap("n", "<Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<Right>", ":vertical resize +2<CR>", opts)

-- quit file
keymap('n', '<C-q>', '<cmd> q <CR>', opts)

-- Buffers
keymap('n', '<Tab>', ':bnext<CR>', opts)
keymap('n', '<S-Tab>', ':bprevious<CR>', opts)

keymap("n", "<leader>ft", ":ToggleTerm<CR>", { noremap = true, silent = true, desc = "Terminal" })
keymap("t", "<ESC>", [[<C-\><C-n>]], { desc = "Escape Terminal Mode" })
keymap("n", "<leader>wv", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
keymap("n", "<leader>hv", "<Cmd>split<CR>", { desc = "Horizontal Split" })
