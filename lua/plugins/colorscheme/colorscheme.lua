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
			"arxngr/tinta.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("tinta").setup({ palette = "tinta-darker" })
			end,
		},
	},
	keys = {
		{ "<leader>uc", "<cmd>Themery<CR>", desc = "Toggle Themery" },
	},
	lazy = false,
	config = function()
		require("themery").setup({
			themes = { "onedark", "tinta" },
		})
	end,
}
