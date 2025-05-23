return {
	"zaldih/themery.nvim",
	dependencies = {
		{
			"navarasu/onedark.nvim",
			priority = 1000, -- make sure to load this before all the other start plugins
			config = function()
				require("onedark").setup({
					style = "darker",
				})
				require("onedark").load()
			end,
		},
		{
			"uloco/bluloco.nvim",
			lazy = true,
			priority = 1000,
			dependencies = { "rktjmp/lush.nvim" },
			config = function() end,
		},
		{
			"arxngr/tinta.nvim",
			lazy = false,
			priority = 1000,
			config = function() end,
		},
	},
	keys = {
		{ "<leader>uc", "<cmd>Themery<CR>", desc = "Toggle Themery" },
	},
	lazy = false,
	config = function()
		require("themery").setup({

			themes = { "onedark", "bluloco", "tinta" },
		})
	end,
}
