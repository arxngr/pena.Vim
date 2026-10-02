return {
	{
		"stevearc/conform.nvim",
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			-- Configure conform.nvim
			require("conform").setup({
				format_after_save = {
					async = true,
				},
				formatters_by_ft = {
					cs = { lsp_format = "prefer" },
					lua = { "stylua" },
					python = { "black" },
					go = { "gofumpt" },
					javascript = { "prettier" },
					javascriptreact = { "prettier" },
					typescript = { "prettier" },
					typescriptreact = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					html = { "prettier" },
					htmldjango = { "djlint" },
					vue = { "prettier" },
					svelte = { "prettier" },
					css = { "prettier" },
					sh = { "shfmt" },
					rust = { "rustfmt" },
					c = { "clang-format" },
					cpp = { "clang-format" },
				},
				formatters = {
					black = {
						prepend_args = { "--fast" },
					},
					prettier = {
						prepend_args = { "--tab-width", "2" },
					},
				},
			})
		end,
	},
}
