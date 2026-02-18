return {
	{
		"uga-rosa/ccc.nvim",
		event = "BufReadPre",
		config = function()
			local ccc = require("ccc")

			ccc.setup({
				highlighter = {
					auto_enable = true, -- show colors automatically
					lsp = true, -- use LSP color info when available
				},
			})

			-- Keymaps
			vim.keymap.set("n", "<leader>cp", "<cmd>CccPick<CR>", { desc = "Color Picker" })
			vim.keymap.set("n", "<leader>cc", "<cmd>CccConvert<CR>", { desc = "Convert Color" })
			vim.keymap.set("n", "<leader>ct", "<cmd>CccToggle<CR>", { desc = "Toggle Colors" })
		end,
	},
}
