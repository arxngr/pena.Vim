return {
	"folke/edgy.nvim",
	event = "VeryLazy",
	keys = {
		{
			"<leader>ue",
			function()
				require("edgy").toggle()
			end,
			desc = "Edgy Toggle",
		},
    -- stylua: ignore
    { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
	},
	opts = function()
		local opts = {
			bottom = {
				{
					ft = "dap-repl",
					title = "DAP REPL",
					size = { height = 0.2 },
				},

				{
					ft = "dapui_console",
					title = "DAP Console",
					size = { height = 0.2 },
				},
				{
					ft = "toggleterm",
					size = { height = 0.2 },
					filter = function(buf, win)
						return vim.api.nvim_win_get_config(win).relative == ""
					end,
				},
				{
					ft = "noice",
					size = { height = 0.2 },
					filter = function(buf, win)
						return vim.api.nvim_win_get_config(win).relative == ""
					end,
				},
				"Trouble",
				{ ft = "qf", title = "QuickFix" },
				{
					ft = "help",
					size = { height = 20 },
					filter = function(buf)
						return vim.bo[buf].buftype == "help"
					end,
				},
				{ title = "Spectre", ft = "spectre_panel", size = { height = 0.4 } },
				{ title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
			},
			left = {
				{
					title = "DAP Scopes",
					ft = "dapui_scopes",
					size = { width = 0.20 },
				},
				{
					title = "DAP Breakpoints",
					ft = "dapui_breakpoints",
					size = { height = 0.2 },
				},
				{
					title = "DAP Stacks",
					ft = "dapui_stacks",
					size = { height = 0.2 },
				},
				{
					title = "DAP Watches",
					ft = "dapui_watches",
					size = { height = 0.2 },
				},
				{ title = "Neotest Summary", ft = "neotest-summary" },
			},
			right = {
				{ title = "Grug Far", ft = "grug-far", size = { width = 0.35 } },
			},
			keys = {
				["<c-Right>"] = function(win)
					win:resize("width", 2)
				end,
				["<c-Left>"] = function(win)
					win:resize("width", -2)
				end,
				["<c-Up>"] = function(win)
					win:resize("height", 2)
				end,
				["<c-Down>"] = function(win)
					win:resize("height", -2)
				end,
			},
		}

		for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
			opts[pos] = opts[pos] or {}
			table.insert(opts[pos], {
				ft = "snacks_terminal",
				size = { height = 0.2 },
				title = "%{b:snacks_terminal.id}: %{b:term_title}",
				filter = function(_buf, win)
					return vim.w[win].snacks_win
						and vim.w[win].snacks_win.position == pos
						and vim.w[win].snacks_win.relative == "editor"
						and not vim.w[win].trouble_preview
				end,
			})
		end
		return opts
	end,
}
