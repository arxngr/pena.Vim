return {
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		opts = function()
			-- walk up the AST to find the nearest node whose type matches any pattern
			local function find_node(patterns)
				local node = vim.treesitter.get_node()
				while node do
					local t = node:type()
					for _, pat in ipairs(patterns) do
						if t == pat or t:find(pat) then return node end
					end
					node = node:parent()
				end
			end

			-- find the body/block child of a node (for inner selection)
			local function find_body(node)
				for i = 0, node:named_child_count() - 1 do
					local child = node:named_child(i)
					local t = child:type()
					if t == "compound_statement" or t == "statement_block"
						or t:find("body") or t:find("block")
					then
						return child
					end
				end
			end

			-- convert treesitter 0-indexed range to mini.ai 1-indexed region
			local function to_region(node)
				local sr, sc, er, ec = node:range()
				if ec == 0 then
					er = er - 1
					ec = #vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
				end
				return { from = { line = sr + 1, col = sc + 1 }, to = { line = er + 1, col = ec } }
			end

			local fn_types    = { "function", "method", "arrow_function", "lambda", "func_literal" }
			local class_types = { "class" }

			return {
				n_lines = 500,
				custom_textobjects = {
					f = function(ai_type)
						local node = find_node(fn_types)
						if not node then return end
						if ai_type == "i" then node = find_body(node) or node end
						return to_region(node)
					end,
					c = function(ai_type)
						local node = find_node(class_types)
						if not node then return end
						if ai_type == "i" then node = find_body(node) or node end
						return to_region(node)
					end,
				},
			}
		end,
	},
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
