return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("edgy").setup({
			animate = {
				enabled = false,
			},
			left = {
				-- {
				-- 	ft = "trouble",
				-- 	pinned = true,
				-- 	title = "Sidebar",
				-- 	filter = function(_buf, win)
				-- 		vim.api.nvim_set_hl(0, "TroubleNormal", { bg = "none", ctermbg = "none" })
				-- 		vim.api.nvim_set_hl(0, "TroubleNormalNC", { bg = "none", ctermbg = "none" })
				--
				-- 		local trouble_data = vim.w[win] and vim.w[win].trouble
				-- 		return trouble_data and trouble_data.mode == "symbols"
				-- 	end,
				-- 	open = "Trouble symbols position=left focus=false filter.buf=0",
				-- 	size = { width = 0.15 },
				-- },
			},
			bottom = {
				{
					title = "ToggleTerm",
					ft = "toggleterm",
					size = { height = 0.25 }, -- 23% of total height
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
