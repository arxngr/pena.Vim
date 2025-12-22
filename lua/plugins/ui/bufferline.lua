return {
	"akinsho/bufferline.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
		{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
		{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
		{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
		{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
		{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
	},
	opts = {
		options = {
			close_command = function(bufnr)
				if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
					if not vim.api.nvim_buf_get_option(bufnr, "modified") then
						vim.cmd("bdelete " .. bufnr)
					end
				end
			end,
			right_mouse_command = function(bufnr)
				if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
					if not vim.api.nvim_buf_get_option(bufnr, "modified") then
						vim.cmd("bdelete " .. bufnr)
					end
				end
			end,
			diagnostics = "nvim_lsp",
			always_show_bufferline = false,
			diagnostics_indicator = function(_, _, diag)
				local icons = {
					Error = " ",
					Warn = " ",
					Info = " ",
					Hint = " ",
				}
				local ret = (diag.error and icons.Error .. diag.error .. " " or "")
					.. (diag.warning and icons.Warn .. diag.warning or "")
				return vim.trim(ret)
			end,
			offsets = {
				{
					filetype = "neo-tree",
					text = "Neo-tree",
					highlight = "Directory",
					text_align = "left",
				},
				{
					filetype = "snacks_layout_box",
				},
			},
			get_element_icon = function(opts)
				local icons = {
					lua = "",
					python = "",
					javascript = "",
					typescript = "",
					markdown = "",
					html = "",
					css = "",
					json = "",
				}
				return icons[opts.filetype]
			end,
		},
	},
	config = function(_, opts)
		require("bufferline").setup(opts)

		-- Refresh bufferline after session load or buffer changes
		vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
			callback = function()
				vim.schedule(function()
					pcall(function()
						vim.cmd("BufferLineRefresh")
					end)
				end)
			end,
		})
	end,
}
