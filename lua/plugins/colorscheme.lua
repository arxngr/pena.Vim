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
		{
			"0xstepit/flow.nvim",
			lazy = false,
			priority = 1000,
			tag = "v2.0.1",
			opts = {
				theme = {
					style = "dark", --  "dark" | "light"
					contrast = "default", -- "default" | "high"
					transparent = false, -- true | false
				},
				colors = {
					mode = "default", -- "default" | "dark" | "light"
					fluo = "pink", -- "pink" | "cyan" | "yellow" | "orange" | "green"
					custom = {
						saturation = "", -- "" | string representing an integer between 0 and 100
						light = "", -- "" | string representing an integer between 0 and 100
					},
				},
				ui = {
					borders = "inverse", -- "theme" | "inverse" | "fluo" | "none"
					aggressive_spell = false, -- true | false
				},
			},
			config = function(_, opts)
				require("flow").setup(opts)
				vim.cmd("colorscheme flow")
			end,
		},
	},
	keys = {
		{ "<leader>uc", "<cmd>Themery<CR>", desc = "Toggle Themery" },
	},
	lazy = false,
	config = function()
		require("themery").setup({

			themes = { "onedark", "bluloco", "tinta", "flow" },
		})
	end,
}
