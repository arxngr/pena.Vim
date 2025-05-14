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

-- Insert mode window navigation (escape to normal mode, then move)
keymap("i", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
keymap("i", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
keymap("i", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
keymap("i", "<C-l>", [[<C-\><C-n><C-w>l]], opts)

-- Terminal mode window navigation (escape to normal mode, then move)
keymap("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
keymap("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
keymap("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
keymap("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)

keymap("n", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
keymap("n", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
keymap("n", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
keymap("n", "<C-l>", [[<C-\><C-n><C-w>l]], opts)
-- Resize windows with arrows
keymap("n", "<Up>", ":resize -2<CR>", opts)
keymap("n", "<Down>", ":resize +2<CR>", opts)
keymap("n", "<Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<Right>", ":vertical resize +2<CR>", opts)

-- quit file
keymap("n", "<C-q>", "<cmd> q <CR>", opts)

-- Buffers
keymap("n", "<Tab>", ":bnext<CR>", opts)
keymap("n", "<S-Tab>", ":bprevious<CR>", opts)

keymap("n", "<leader>ft", ":ToggleTerm<CR>", opts)
keymap("t", "<ESC>", [[<C-\><C-n>]], { desc = "Escape Terminal Mode" })
keymap("n", "<leader>wv", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
keymap("n", "<leader>hv", "<Cmd>split<CR>", { desc = "Horizontal Split" })

keymap({ "n" }, "<C-k>", function()
	require("lsp_signature").toggle_float_win()
end, { silent = true, noremap = true, desc = "toggle signature" })

keymap({ "n" }, "<Leader>k", function()
	vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "toggle signature" })

keymap("n", "<leader>cr", vim.lsp.buf.rename, opts)
