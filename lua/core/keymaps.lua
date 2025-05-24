local utils = require("core.utils")
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

-- General
keymap("n", "c", utils.open_config, { desc = "Open config" })
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
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- In terminal mode, map <C-h/j/k/l> to escape and move
keymap("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Terminal left" })
keymap("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Terminal down" })
keymap("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Terminal up" })
keymap("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Terminal right" })
keymap("t", "<C-x>", [[<C-\><C-n>]], { desc = "Escape Terminal Mode" })

-- quit file
keymap("n", "<C-q>", "<cmd> q <CR>", opts)

-- Buffers
keymap("n", "<Tab>", ":bnext<CR>", opts)
keymap("n", "<S-Tab>", ":bprevious<CR>", opts)

keymap("n", "<leader>ft", ":FloatermToggle<CR>", opts)
keymap("n", "<leader>wv", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
keymap("n", "<leader>hv", "<Cmd>split<CR>", { desc = "Horizontal Split" })

keymap({ "n" }, "<Leader>k", function()
	vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "toggle signature" })

keymap("n", "<leader>cr", vim.lsp.buf.rename, opts)
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")
