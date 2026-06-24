return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local langs = {
				"c", "cpp", "asm", "lua", "python", "javascript", "typescript",
				"vimdoc", "vim", "regex", "terraform", "sql", "dockerfile",
				"toml", "json", "java", "groovy", "go", "gitignore", "graphql",
				"yaml", "make", "cmake", "markdown", "markdown_inline", "bash",
				"tsx", "css", "html",
			}

			local ts_ok, ts = pcall(require, "nvim-treesitter.configs")
			if not ts_ok then ts = require("nvim-treesitter") end
			ts.setup({ ensure_installed = langs, auto_install = true })

			-- af/if/ac/ic text objects handled by mini.ai (plugins/utilities/mini.lua)

			-- native movement — no plugin dependency, works on all OSes
			local FN_TYPES = {
				function_definition = true, function_declaration = true,
				function_item = true,        -- Rust
				method_definition = true,    -- JS/TS
				method_declaration = true,   -- Java/Go
				local_function = true,       -- Lua
				arrow_function = true,       -- JS/TS
				function_expression = true,  -- JS
				anonymous_function = true,   -- PHP
				lambda_expression = true,    -- C++
			}
			local CLASS_TYPES = {
				class_definition = true, class_declaration = true,
				class_specifier = true,  -- C++
				struct_item = true,      -- Rust
				impl_item = true,        -- Rust
			}

			local function collect(type_set)
				local parser = vim.treesitter.get_parser(0)
				if not parser then return {} end
				local nodes = {}
				parser:for_each_tree(function(tree)
					local function walk(node)
						if type_set[node:type()] then
							table.insert(nodes, node)
						end
						for i = 0, node:child_count() - 1 do
							walk(node:child(i))
						end
					end
					walk(tree:root())
				end)
				table.sort(nodes, function(a, b) return (a:start()) < (b:start()) end)
				return nodes
			end

			local function jump(dir, type_set)
				local nodes = collect(type_set)
				if #nodes == 0 then return end
				local cur = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed row
				local target
				if dir == "next" then
					for _, n in ipairs(nodes) do
						if (n:start()) > cur then target = n; break end
					end
				else
					for i = #nodes, 1, -1 do
						if (nodes[i]:start()) < cur then target = nodes[i]; break end
					end
				end
				if target then
					vim.cmd("normal! m'")  -- save position to jumplist
					vim.api.nvim_win_set_cursor(0, { (target:start()) + 1, 0 })
				end
			end

			vim.keymap.set("n", "]f", function() jump("next", FN_TYPES)    end, { desc = "Next function" })
			vim.keymap.set("n", "[f", function() jump("prev", FN_TYPES)    end, { desc = "Prev function" })
			vim.keymap.set("n", "]c", function() jump("next", CLASS_TYPES) end, { desc = "Next class" })
			vim.keymap.set("n", "[c", function() jump("prev", CLASS_TYPES) end, { desc = "Prev class" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		lazy = false,
		config = function()
			require("treesitter-context").setup({
				enable = true,
				max_lines = 0,
				trim_scope = "outer",
				mode = "cursor",
				separator = nil,
			})
		end,
	},
}
