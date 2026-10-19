return {
	"zaldih/themery.nvim",
	dependencies = {
		{
			"navarasu/onedark.nvim",
			priority = 1000, -- make sure to load this before all the other start plugins
			config = function()
				vim.o.background = "dark"
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
				require("tinta").setup({ palette = "tinta-darker-cool" })
			end,
		},
		{
			"uloco/bluloco.nvim",
			dependencies = { "rktjmp/lush.nvim" },
			opts = {},
		},
	},
	keys = {
		{ "<leader>uc", "<cmd>Themery<CR>", desc = "Toggle Themery" },
	},
	lazy = false,
	config = function()
		local themes = {}
		for _, style in ipairs({ "darker", "dark", "cool", "deep", "warm", "warmer", "light" }) do
			themes[#themes + 1] = {
				name = "OneDark (" .. style .. ")",
				colorscheme = "onedark",
				before = string.format(
					"vim.o.background = %q; require('onedark').setup({ style = %q })",
					style == "light" and "light" or "dark",
					style
				),
			}
		end
		for _, theme in ipairs({ "tinta", "bluloco-dark", "bluloco-light" }) do
			themes[#themes + 1] = theme
		end
		require("themery").setup({
			themes = themes,
		})
	end,
}
