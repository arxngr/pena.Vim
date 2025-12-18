local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
vim.g.mapleader = " "

-- General
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

keymap("n", "<leader>wv", "<Cmd>vsplit<CR>", { desc = "Vertical Split" })
keymap("n", "<leader>hv", "<Cmd>split<CR>", { desc = "Horizontal Split" })

keymap({ "n" }, "<Leader>k", function()
	vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "Toggle signature" })

keymap("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename code", remap = true })
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")
keymap("n", "<leader>bd", ":bd<CR>", { desc = "Close Buffer" })

keymap("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Open float diagnostic", remap = true })

local diagnostic_goto = function(next, severity)
	return function()
		vim.diagnostic.jump({
			count = (next and 1 or -1) * vim.v.count1,
			severity = severity and vim.diagnostic.severity[severity] or nil,
			float = true,
		})
	end
end
keymap("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
keymap("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
keymap("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
keymap("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
keymap("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
keymap("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
