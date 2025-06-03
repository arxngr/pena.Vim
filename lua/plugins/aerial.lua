return {
	"stevearc/aerial.nvim",
	opts = {
		open_automatic = true,
		attach_mode = "window",
		backends = { "lsp", "treesitter", "markdown" },
		highlight_on_hover = true,
		highlight_on_jump = true,
		show_guides = true,
		filter_kind = false,

		layout = {
			default_direction = "left",
			placement = "edge",
			min_width = 0.18,
			max_width = 0.18,
			preserve_equality = false,
		},

		manage_folds = false,

		close_automatic_events = { "unsupported", "unfocus", "buf_hidden" },
	},

	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},

	event = "BufReadPost",

	keys = {
		{ "<leader>cs", "<cmd>AerialToggle<CR>", desc = "Aerial (Toggle Symbols)" },
		{ "<leader>cj", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
		{ "<leader>ck", "<cmd>AerialPrev<CR>", desc = "Previous Symbol" },
	},
}
