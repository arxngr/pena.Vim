return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
					delay = 300,
					ignore_whitespace = false,
				},
				current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d %H:%M> - <summary>",
			})
		end,
	},
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G" }, -- lazy-load when these commands are used
		keys = {
			{ "<leader>gs", ":Git<CR>", desc = "Git status" },
			{ "<leader>gc", ":Git commit<CR>", desc = "Git commit" },
			{ "<leader>gp", ":Git push<CR>", desc = "Git push" },
			{ "<leader>gb", ":Git blame<CR>", desc = "Git blame" },
			{ "<leader>gd", ":Gvdiffsplit<CR>", desc = "Git diff split" },
		},
	},
}
