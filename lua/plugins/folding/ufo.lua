return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async", -- required for ufo
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local ufo = require("ufo")
		ufo.setup({
			provider_selector = function()
				return { "treesitter", "indent" }
			end,
		})
		vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
	end,
}
