return {
	"stevearc/oil.nvim",
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	lazy = false,
	opts = function()
		local utils = require("core.utils")
		local dims = utils.get_floating_dimensions()
		-- Make Oil 15% bigger than the standard (0.8 * 1.15 = 0.92)
		local scale = 1.15
		local width = math.floor(dims.width * scale)
		local height = math.floor(dims.height * scale)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		return {
			float = {
				padding = 0,
				max_width = width,
				max_height = height,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				override = function(conf)
					conf.row = row
					conf.col = col
					return conf
				end,
			},
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = true,
			},
		}
	end,

	keys = {
		{
			"<leader>e",
			function()
				require("oil").toggle_float()
			end,
			desc = "Toggle Oil (float)",
		},
	},
}
