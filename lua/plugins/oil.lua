return {
	"stevearc/oil.nvim",
	dependencies = { { "nvim-mini/mini.icons", opts = {} } },
	lazy = false,
	opts = {
		float = {
			padding = 2,
			max_width = 100,
			max_height = 45,
			border = "rounded",
			win_options = {
				winblend = 0,
			},
		},
		view_options = {
			-- Show files and directories that start with "."
			show_hidden = true,
		},
	},

	keys = {
		{
			"<leader>e",
			function()
				require("oil").toggle_float()
			end,
			desc = "Toggle Oil (float)",
		},
	},
}
