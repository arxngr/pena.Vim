return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("edgy").setup({
			bottom = {
				{
					title = "ToggleTerm",
					ft = "toggleterm",
					size = { height = 0.23 }, -- 23% of total height
					pinned = false,
					open = "ToggleTerm direction=horizontal",
					filter = function(buf, win)
						-- Only open if not already visible

						return vim.api.nvim_win_get_config(win).relative == ""
					end,
				},
				{
					title = "DAP REPL",
					ft = "dap-repl",
					size = { height = 0.23 }, -- 23% of total height
					pinned = false,
					open = function()
						require("dap").repl.open()
					end,
				},
			},
		})
	end,
}
