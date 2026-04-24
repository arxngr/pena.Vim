return { -- Highlight, edit, and navigate code
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		event = { "BufReadPost", "BufNewFile" },
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		opts = {
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
			refactor = {
				smart_rename = {
					enable = true,
					keymaps = {
						smart_rename = "<leader>cr",
					},
				},
			},
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
					},
				},
				move = {
					enable = true,
					goto_next_start = {
						["]f"] = "@function.outer",
						["]c"] = "@class.outer",
						["]a"] = "@parameter.inner",
					},
					goto_next_end = {
						["]F"] = "@function.outer",
						["]C"] = "@class.outer",
						["]A"] = "@parameter.inner",
					},
					goto_previous_start = {
						["[f"] = "@function.outer",
						["[c"] = "@class.outer",
						["[a"] = "@parameter.inner",
					},
					goto_previous_end = {
						["[F"] = "@function.outer",
						["[C"] = "@class.outer",
						["[A"] = "@parameter.inner",
					},
				},
			},
		},
		keys = {
			{ "<c-space>", desc = "Increment Selection" },
			{ "<bs>", desc = "Decrement Selection", mode = "x" },
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		config = function(_, opts)
			-- v0.12.0+ removed the `setup()` call entirely.
			-- Config is now applied via module-level calls instead.
			local ok, ts = pcall(require, "nvim-treesitter")
			if ok and ts.setup then
				-- Older API (< 0.12.0): setup() still exists
				ts.setup(opts)
			else
				-- New API (>= 0.12.0): configure each module directly
				local configs = require("nvim-treesitter.configs")
				configs.setup(opts)
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
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
