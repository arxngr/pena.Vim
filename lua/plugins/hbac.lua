return {
	"axkirillov/hbac.nvim",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("hbac").setup({
			autoclose = true, -- automatically close unused buffers
			threshold = 5, -- keep only 5 buffers max
			close_command = function(bufnr)
				vim.cmd("Bdelete! " .. bufnr)
			end,
			exclude_filetypes = {
				"toggleterm",
				"oil",
				"dap-repl",
				"dapui_scopes",
				"dapui_breakpoints",
				"dapui_stacks",
				"dapui_watches",
				"dapui_console",
			},
			exclude_buffers = {}, -- (Optional) exact buffer names to never close
		})
	end,
}
