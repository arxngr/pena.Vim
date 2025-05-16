return {
	"echasnovski/mini.diff",
	event = "VeryLazy",
	keys = {
		{
			"<leader>go",
			function()
				require("mini.diff").toggle_overlay(0)
			end,
			desc = "Toggle mini.diff overlay",
		},
	},
	opts = {
		view = {
			style = "sign",
			signs = {
				add = "▎",
				change = "▎",
				delete = "",
			},
		},
	},
	{
		"echasnovski/mini.move",
		opts = {
			mappings = {
				-- Directional movement for selected text or lines
				left = "<M-h>",
				right = "<M-l>",
				down = "<M-j>",
				up = "<M-k>",

				-- Move selection line in visual mode
				line_left = "<M-h>",
				line_right = "<M-l>",
				line_down = "<M-j>",
				line_up = "<M-k>",
			},
			options = {
				-- Automatically reindent selection during linewise vertical move
				reindent_linewise = true,
			},
		},
	},
	{
		"echasnovski/mini.surround",
		config = function()
			require("mini.surround").setup({
				mappings = {
					add = "gsa", -- Add surrounding in Normal and Visual modes (now with 'g')
					delete = "gsd", -- Delete surrounding (now with 'g')
					find = "gsf", -- Find surrounding (to the right) (now with 'g')
					find_left = "gsF", -- Find surrounding (to the left) (now with 'g')
					highlight = "gsh", -- Highlight surrounding (now with 'g')
					replace = "gsr", -- Replace surrounding (now with 'g')
					update_n_lines = "gsn", -- Update `n_lines` (now with 'g')
				},
			})
		end,
	},
	{
		"echasnovski/mini.pairs",
		event = "VeryLazy",
		opts = {
			modes = { insert = true, command = true, terminal = false },
			-- skip autopair when next character is one of these
			skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
			-- skip autopair when the cursor is inside these treesitter nodes
			skip_ts = { "string" },
			-- skip autopair when next character is closing pair
			-- and there are more closing pairs than opening pairs
			skip_unbalanced = true,
			-- better deal with markdown code blocks
			markdown = true,
		},
		config = function(_, opts)
			require("mini.pairs").setup(opts)
		end,
	},
}
