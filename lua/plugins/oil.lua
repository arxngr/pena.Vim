return {
	"stevearc/oil.nvim",
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	lazy = false,
	opts = {
		float = {
			padding = 2,
			max_width = 80,
			max_height = 35,
			border = "rounded",
			win_options = {
				winblend = 0,
			},
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
