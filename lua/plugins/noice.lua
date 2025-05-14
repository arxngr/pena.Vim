return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		cmdline = {
			enabled = true,
			view = "cmdline_popup", -- this makes it float
			format = {
				cmdline = { icon = "", title = "", title_pos = "center" },
			},
		},
		views = {
			cmdline_popup = {
				position = {
					row = "50%", -- center vertically
					col = "50%", -- center horizontally
				},
				size = {
					width = 60,
					height = "auto",
				},
				border = {
					style = "rounded",
				},
				win_options = {
					winblend = 10,
					winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
				},
			},
		},
		presets = {
			command_palette = true, -- optional style
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
}
