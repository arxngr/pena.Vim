return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("edgy").setup({
			left = {},
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
				{
					title = "Console",
					ft = "", -- match all filetypes (or empty)
					size = { height = 0.23 },
					filter = function(buf)
						local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
						return buftype == "terminal"
					end,
				},
			},
		})
	end,
}
