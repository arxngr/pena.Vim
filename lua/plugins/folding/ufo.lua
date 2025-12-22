return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async", -- required for ufo
		"nvim-treesitter/nvim-treesitter", -- or LSP
	},
	config = function()
		require("ufo").setup()
	end,
}
