return {
	{
		"vim-test/vim-test",
		config = function()
			vim.g["test#go#runner"] = "gotest"
			vim.g["test#strategy"] = "neovim"

			vim.api.nvim_set_keymap("n", "<leader>tn", ":TestNearest<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>tf", ":TestFile<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>ts", ":TestSuite<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>tl", ":TestLast<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>tv", ":TestVisit<CR>", { noremap = true, silent = true })

			vim.g["test#neovim#term_position"] = "vert"
			vim.g["test#neovim#start_normal"] = 1
		end,
	},
}
