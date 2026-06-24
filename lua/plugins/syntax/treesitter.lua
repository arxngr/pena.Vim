return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter-textobjects", lazy = false },
		},
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

			-- af/if/ac/ic text objects are handled by mini.ai (see plugins/utilities/mini.lua)

			-- movement keymaps via nvim-treesitter-textobjects (silently skip if broken)
			local mov_ok, mov = pcall(require, "nvim-treesitter.textobjects.move")
			if mov_ok then
				local function mv(fn, ...)
					local args = { ... }
					return function() pcall(fn, table.unpack(args)) end
				end
				vim.keymap.set("n", "]f", mv(mov.goto_next_start,     "@function.outer",  "textobjects"))
				vim.keymap.set("n", "]c", mv(mov.goto_next_start,     "@class.outer",     "textobjects"))
				vim.keymap.set("n", "]a", mv(mov.goto_next_start,     "@parameter.inner", "textobjects"))
				vim.keymap.set("n", "]F", mv(mov.goto_next_end,       "@function.outer",  "textobjects"))
				vim.keymap.set("n", "]C", mv(mov.goto_next_end,       "@class.outer",     "textobjects"))
				vim.keymap.set("n", "]A", mv(mov.goto_next_end,       "@parameter.inner", "textobjects"))
				vim.keymap.set("n", "[f", mv(mov.goto_previous_start, "@function.outer",  "textobjects"))
				vim.keymap.set("n", "[c", mv(mov.goto_previous_start, "@class.outer",     "textobjects"))
				vim.keymap.set("n", "[a", mv(mov.goto_previous_start, "@parameter.inner", "textobjects"))
				vim.keymap.set("n", "[F", mv(mov.goto_previous_end,   "@function.outer",  "textobjects"))
				vim.keymap.set("n", "[C", mv(mov.goto_previous_end,   "@class.outer",     "textobjects"))
				vim.keymap.set("n", "[A", mv(mov.goto_previous_end,   "@parameter.inner", "textobjects"))
			end
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
