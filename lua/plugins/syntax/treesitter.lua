return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter-textobjects", lazy = false },
		},
		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = {
					"c",
					"cpp",
					"asm",
					"lua",
					"python",
					"javascript",
					"typescript",
					"vimdoc",
					"vim",
					"regex",
					"terraform",
					"sql",
					"dockerfile",
					"toml",
					"json",
					"java",
					"groovy",
					"go",
					"gitignore",
					"graphql",
					"yaml",
					"make",
					"cmake",
					"markdown",
					"markdown_inline",
					"bash",
					"tsx",
					"css",
					"html",
				},
				auto_install = true,
			})

			-- textobjects: select
			local select = require("nvim-treesitter.textobjects.select")
			vim.keymap.set({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end)

			-- textobjects: move
			local move = require("nvim-treesitter.textobjects.move")
			vim.keymap.set("n", "]f", function()
				move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set("n", "]c", function()
				move.goto_next_start("@class.outer", "textobjects")
			end)
			vim.keymap.set("n", "]a", function()
				move.goto_next_start("@parameter.inner", "textobjects")
			end)
			vim.keymap.set("n", "]F", function()
				move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set("n", "]C", function()
				move.goto_next_end("@class.outer", "textobjects")
			end)
			vim.keymap.set("n", "]A", function()
				move.goto_next_end("@parameter.inner", "textobjects")
			end)
			vim.keymap.set("n", "[f", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set("n", "[c", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end)
			vim.keymap.set("n", "[a", function()
				move.goto_previous_start("@parameter.inner", "textobjects")
			end)
			vim.keymap.set("n", "[F", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end)
			vim.keymap.set("n", "[C", function()
				move.goto_previous_end("@class.outer", "textobjects")
			end)
			vim.keymap.set("n", "[A", function()
				move.goto_previous_end("@parameter.inner", "textobjects")
			end)

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
