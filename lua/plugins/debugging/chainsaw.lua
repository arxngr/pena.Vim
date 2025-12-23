return {
	"chrisgrieser/nvim-chainsaw",
	event = "VeryLazy",
	opts = {}, -- required even if left empty
	keys = {
		{
			"<leader>ll",
			function()
				require("chainsaw").variableLog()
			end,
			desc = "Log variable",
		},
		{
			"<leader>lt",
			function()
				require("chainsaw").typeLog()
			end,
			desc = "Log type",
		},
		{
			"<leader>lm",
			function()
				require("chainsaw").messageLog()
			end,
			desc = "Log message",
		},
		{
			"<leader>lr",
			function()
				require("chainsaw").removeLogs()
			end,
			desc = "Remove logs",
		},
	},
}
