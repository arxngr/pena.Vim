return {
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", version = "^1.0.0" },
			{ "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"hrsh7th/cmp-nvim-lsp",
		},
		opts = function()
			local ret = {
				inlay_hints = {
					enabled = true,
					exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
				},
				-- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
				-- Be aware that you also will need to properly configure your LSP server to
				-- provide the code lenses.
				codelens = {
					enabled = false,
				},
				-- add any global capabilities here
				capabilities = {
					workspace = {
						fileOperations = {
							didRename = true,
							willRename = true,
						},
					},
				},
			}
			return ret
		end,
		config = function()
			vim.diagnostic.config({
				virtual_text = {
					prefix = "●",
					spacing = 4,
				},
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			-- Create a dedicated autocmd group for LSP attach events
			local lsp_attach_group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true })

			-- Create an autocmd for LSP attach
			vim.api.nvim_create_autocmd("LspAttach", {
				group = lsp_attach_group,
				callback = function(event)
					-- Define keymapping function for this buffer
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Set up each keybinding individually
					map("gd", require("telescope.builtin").lsp_definitions, "Goto Definition")
					map("gr", require("telescope.builtin").lsp_references, "Goto References")
					map("gI", require("telescope.builtin").lsp_implementations, "Goto Implementation")
					map("gt", require("telescope.builtin").lsp_type_definitions, "Type Definition")
					map("<leader>gs", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
					map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace Symbols")
					map("<leader>rn", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
					map("gD", vim.lsp.buf.declaration, "Goto Declaration")

					-- Get client by ID
					local client = vim.lsp.get_client_by_id(event.data.client_id)

					-- Handle inlay hints if available
					if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
						map("<leader>uh", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, "Toggle Inlay Hints")

						vim.lsp.inlay_hint.enable()
					end

					-- Create a BufWritePre autocmd specifically for this buffer
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = event.buf,
						callback = function()
							-- Apply inlay hints if supported
							if client.supports_method("textDocument/inlayHint") then
								vim.lsp.inlay_hint(event.buf, true)
							end

							-- Handle imports organization if supported
							if client.supports_method("textDocument/codeAction") then
								local params = vim.lsp.util.make_range_params()
								params.context = { only = { "source.organizeImports" } }

								local result =
									vim.lsp.buf_request_sync(event.buf, "textDocument/codeAction", params, 1000)
								for _, res in pairs(result or {}) do
									for _, action in pairs(res.result or {}) do
										if action.edit then
											vim.lsp.util.apply_workspace_edit(
												action.edit,
												client.offset_encoding or "utf-16"
											)
										elseif action.command then
											vim.lsp.buf.execute_command(action.command)
										end
									end
								end
							end
							-- Apply formatting if supported
							if client.supports_method("textDocument/formatting") then
								vim.lsp.buf.format({ async = false })
							end
						end,
					})
				end,
			})

			-- Setup capabilities explicitly
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
			capabilities.textDocument.semanticTokens = {
				dynamicRegistration = false,
				requests = {
					range = true,
					full = true,
				},
				tokenTypes = {
					"namespace",
					"type",
					"class",
					"enum",
					"interface",
					"struct",
					"typeParameter",
					"parameter",
					"variable",
					"property",
					"enumMember",
					"event",
					"function",
					"method",
					"macro",
					"keyword",
					"modifier",
					"comment",
					"string",
					"number",
					"regexp",
					"operator",
				},
				tokenModifiers = {
					"declaration",
					"definition",
					"readonly",
					"static",
					"deprecated",
					"abstract",
					"async",
					"modification",
					"documentation",
					"defaultLibrary",
				},
				formats = { "relative" },
				overlappingTokenSupport = true,
				multilineTokenSupport = true,
			}
			-- Define server configurations - each one individually configured
			local servers = {}

			-- Setup Mason
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
				log_level = vim.log.levels.INFO,
				max_concurrent_installers = 4,
			})

			-- Create a dedicated list of servers to ensure are installed
			local ensure_installed = {
				"stylua", -- Lua formatter
				"gopls", -- Go language server
				"clangd", -- C/C++ language server
				"pyright", -- Python language server
				"vtsls", -- TypeScript and JavaScript language server
				"html", -- HTML language server
				"cssls", -- CSS language server
				"phpactor", -- PHP language server
			}

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
				auto_update = false,
				run_on_start = true,
			})

			-- Setup mason-lspconfig with each server configured individually
			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						-- Get server configuration or use empty table
						local server = servers[server_name] or {}

						-- Extend capabilities - we do this for each server
						local server_capabilities = vim.deepcopy(capabilities)
						if server.capabilities then
							server_capabilities = vim.tbl_deep_extend("force", server_capabilities, server.capabilities)
						end
						server.capabilities = server_capabilities

						-- Set up this specific server
						require("lspconfig")[server_name].setup(server)
					end,

					-- Add server-specific handlers for semantic tokens
					["rust_analyzer"] = function()
						require("lspconfig").rust_analyzer.setup({
							capabilities = capabilities,
							settings = {
								["rust-analyzer"] = {
									checkOnSave = {
										command = "clippy",
									},
									semanticHighlighting = {
										operator = { enable = true },
										punctuation = { enable = true },
									},
									inlayHints = {
										chainingHints = true,
										parameterHints = true,
										typeHints = true,
									},
								},
							},
						})
					end,

					["gopls"] = function()
						require("lspconfig").gopls.setup({
							capabilities = capabilities,
							cmd = { "gopls" },
							filetypes = { "go", "gomod", "gowork", "gotmpl" },
							root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
							settings = {
								gopls = {
									semanticTokens = true,
									usePlaceholders = false,
									analyses = {
										unusedparams = true,
										shadow = true,
									},
									hints = {
										assignVariableTypes = true,
										compositeLiteralFields = true,
										compositeLiteralTypes = true,
										constantValues = true,
										functionTypeParameters = true,
										parameterNames = true,
										rangeVariableTypes = true,
									},
									analyses = {
										nilness = true,
										unusedparams = true,
										unusedwrite = true,
										useany = true,
									},
									gofumpt = true,
									codelenses = {
										gc_details = false,
										generate = true,
										regenerate_cgo = true,
										run_govulncheck = true,
										test = true,
										tidy = true,
										upgrade_dependency = true,
										vendor = true,
									},
								},
							},
						})
					end,

					["pyright"] = function()
						require("lspconfig").pyright.setup({
							capabilities = capabilities,
							settings = {
								python = {
									analysis = {
										autoSearchPaths = true,
										useLibraryCodeForTypes = true,
										diagnosticMode = "workspace",
										typeCheckingMode = "basic",
									},
								},
							},
						})
					end,
				},
				["clangd"] = function()
					require("lspconfig").clangd.setup({
						capabilities = vim.tbl_deep_extend("force", {}, capabilities, {
							offsetEncoding = { "utf-16" },
						}),
						cmd = {
							"clangd",
							"--background-index",
							"--clang-tidy",
							"--header-insertion=iwyu",
							"--completion-style=detailed",
							"--function-arg-placeholders=0",
							"--fallback-style=llvm",
						},
						init_options = {
							usePlaceholders = false,
							completeUnimported = true,
							clangdFileStatus = true,
						},
					})
				end,
			})
		end,
	},

	{
		"ray-x/lsp_signature.nvim",
		event = "LspAttach",
		config = function()
			require("lsp_signature").setup({
				bind = true,
				handler_opts = {
					border = "rounded",
				},
				hint_enable = false,
				floating_window = false,
				-- Could add more repeated configuration here
				doc_lines = 10,
				max_height = 12,
				max_width = 80,
				wrap = false,
				timer_interval = 200,
				hi_parameter = "Search",
				toggle_key = "<M-x>",
				select_signature_key = "<M-n>",
				move_cursor_key = "<M-m>",
			})
		end,
	},
}
