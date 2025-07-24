return {
	{
		"folke/trouble.nvim",
		cmd = { "Trouble" },
		opts = {
			modes = {
				symbols = {
					filter = {
						["not"] = { ft = "lua", kind = "Package" },
						any = {
							ft = { "help", "markdown" },
							kind = {
								"Class",
								"Constructor",
								"Enum",
								"Field",
								"Function",
								"Interface",
								"Method",
								"Module",
								"Namespace",
								"Package",
								"Struct",
								"Trait",
								"Variable",
							},
						},
					},
				},
				diagnostics = {
					win = {
						type = "float",
						relative = "editor",
						border = "rounded",
						width = 0.8,
						height = 0.4,
					},
				},
				lsp = {
					win = {
						type = "float",
						relative = "editor",
						border = "rounded",
						width = 0.8,
						height = 0.4,
					},
				},
			},
		},
		keys = function()
			local function map_toggle_focus(mode_name, desc, opts)
				opts = opts or {}
				return {
					opts.key,
					function()
						local trouble = require("trouble")
						if trouble.is_open() then
							trouble.close()
						else
							trouble.toggle(mode_name, opts.toggle_opts)
							trouble.focus()
						end
					end,
					desc = desc,
					mode = "n",
				}
			end

			local function fallback_nav(cmd)
				local ok, err = pcall(vim.cmd[cmd])
				if not ok then
					vim.notify(err, vim.log.levels.ERROR)
				end
			end

			return {
				map_toggle_focus("diagnostics", "Diagnostics (Trouble)", { key = "<leader>xx" }),
				map_toggle_focus("diagnostics", "Buffer Diagnostics (Trouble)", {
					key = "<leader>xX",
					toggle_opts = { buf = 0 },
				}),
				map_toggle_focus("symbols", "Symbols (Trouble)", { key = "<leader>cs" }),
				map_toggle_focus("lsp", "LSP references/definitions/... (Trouble)", { key = "<leader>cS" }),
				map_toggle_focus("loclist", "Location List (Trouble)", { key = "<leader>xL" }),
				map_toggle_focus("qflist", "Quickfix List (Trouble)", { key = "<leader>xQ" }),
				{
					"[q",
					function()
						local trouble = require("trouble")
						if trouble.is_open() then
							trouble.prev({ skip_groups = true, jump = true })
						else
							fallback_nav("cprev")
						end
					end,
					desc = "Previous Trouble/Quickfix Item",
					mode = "n",
				},
				{
					"]q",
					function()
						local trouble = require("trouble")
						if trouble.is_open() then
							trouble.next({ skip_groups = true, jump = true })
						else
							fallback_nav("cnext")
						end
					end,
					desc = "Next Trouble/Quickfix Item",
					mode = "n",
				},
			}
		end,
		config = function(_, opts)
			local trouble = require("trouble")
			trouble.setup(opts)

			local telescope = require("telescope")
			local open_with_trouble = require("trouble.sources.telescope").open

			telescope.setup({
				defaults = {
					mappings = {
						i = { ["<c-t>"] = open_with_trouble },
						n = { ["<c-t>"] = open_with_trouble },
					},
				},
			})
		end,
	},
}
