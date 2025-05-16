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
			-- Configure diagnostics explicitly with all options spelled out
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

					-- Handle document highlighting
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						-- Create a specific highlight group for this feature
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })

						-- Create autocmd for highlighting on cursor hold
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						-- Create autocmd for clearing highlights on cursor moved
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						-- Create a detach group and autocmd to clean up
						local lsp_detach_group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true })
						vim.api.nvim_create_autocmd("LspDetach", {
							group = lsp_detach_group,
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end
				end,
			})

			-- Setup capabilities explicitly
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			-- Enable semantic tokens explicitly
			capabilities.textDocument.semanticTokens = {
				dynamicRegistration = false,
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
					"decorator",
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
				requests = {
					range = true,
					full = { delta = true },
				},
				multilineTokenSupport = false,
				overlappingTokenSupport = false,
				serverCancellationSupport = true,
				augmentsSyntaxTokens = true,
			}
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			-- Define server configurations - each one individually configured
			local servers = {
				clangd = {
					keys = {
						{ "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
					},
					root_dir = function(fname)
						return require("lspconfig.util").root_pattern(
							"Makefile",
							"configure.ac",
							"configure.in",
							"config.h.in",
							"meson.build",
							"meson_options.txt",
							"build.ninja"
						)(fname) or require("lspconfig.util").root_pattern(
							"compile_commands.json",
							"compile_flags.txt"
						)(fname) or require("lspconfig.util").find_git_ancestor(fname)
					end,
					capabilities = {
						offsetEncoding = { "utf-16" },
					},
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
				},
				gopls = {
					capabilities = capabilities,
					cmd = { "gopls" },
					filetypes = { "go", "gomod", "gowork", "gotmpl" },
					root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
				},
				pyright = {
					capabilities = capabilities,
					cmd = { "pyright-langserver", "--stdio" },
					filetypes = { "python" },
					root_dir = require("lspconfig.util").root_pattern(
						"pyproject.toml",
						"setup.py",
						"setup.cfg",
						"requirements.txt",
						".git"
					),
					settings = {
						python = {
							analysis = {
								autoSearchPaths = true,
								diagnosticMode = "workspace",
								useLibraryCodeForTypes = true,
							},
						},
					},
				},
				ts_ls = {
					capabilities = capabilities,
					cmd = { "typescript-language-server", "--stdio" },
					filetypes = {
						"javascript",
						"javascriptreact",
						"javascript.jsx",
						"typescript",
						"typescriptreact",
						"typescript.tsx",
					},
					root_dir = require("lspconfig.util").root_pattern(
						"package.json",
						"tsconfig.json",
						"jsconfig.json",
						".git"
					),
					-- Explicitly enable semantic tokens for TypeScript/JavaScript
					settings = {
						typescript = {
							semanticTokens = true,
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
						javascript = {
							semanticTokens = true,
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				},
				ruff = {
					capabilities = capabilities,
					cmd = { "ruff-lsp" },
					filetypes = { "python" },
					root_dir = require("lspconfig.util").root_pattern(
						"pyproject.toml",
						"setup.py",
						"setup.cfg",
						"requirements.txt",
						".git"
					),
				},
				pylsp = {
					capabilities = capabilities,
					cmd = { "pylsp" },
					filetypes = { "python" },
					root_dir = require("lspconfig.util").root_pattern(
						"pyproject.toml",
						"setup.py",
						"setup.cfg",
						"requirements.txt",
						".git"
					),
					settings = {
						pylsp = {
							plugins = {
								pyflakes = { enabled = false },
								pycodestyle = { enabled = false },
								autopep8 = { enabled = false },
								yapf = { enabled = false },
								mccabe = { enabled = false },
								pylsp_mypy = { enabled = false },
								pylsp_black = { enabled = false },
								pylsp_isort = { enabled = false },
							},
						},
					},
				},
				html = {
					capabilities = capabilities,
					cmd = { "vscode-html-language-server", "--stdio" },
					filetypes = { "html", "twig", "hbs" },
					root_dir = require("lspconfig.util").root_pattern("package.json", ".git"),
				},
				cssls = {
					capabilities = capabilities,
					cmd = { "vscode-css-language-server", "--stdio" },
					filetypes = { "css", "scss", "less" },
					root_dir = require("lspconfig.util").root_pattern("package.json", ".git"),
				},
				tailwindcss = {
					capabilities = capabilities,
					cmd = { "tailwindcss-language-server", "--stdio" },
					filetypes = {
						"html",
						"css",
						"scss",
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
					},
					root_dir = require("lspconfig.util").root_pattern(
						"tailwind.config.js",
						"tailwind.config.ts",
						"postcss.config.js",
						"postcss.config.ts",
						"package.json",
						".git"
					),
				},
				dockerls = {
					capabilities = capabilities,
					cmd = { "docker-langserver", "--stdio" },
					filetypes = { "dockerfile" },
					root_dir = require("lspconfig.util").root_pattern("Dockerfile", ".git"),
				},
				sqlls = {
					capabilities = capabilities,
					cmd = { "sql-language-server", "up", "--method", "stdio" },
					filetypes = { "sql", "mysql", "postgresql" },
					root_dir = require("lspconfig.util").root_pattern(".git"),
				},
				terraformls = {
					capabilities = capabilities,
					cmd = { "terraform-ls", "serve" },
					filetypes = { "terraform", "terraform-vars" },
					root_dir = require("lspconfig.util").root_pattern(".terraform", ".git"),
				},
				jsonls = {
					capabilities = capabilities,
					cmd = { "vscode-json-language-server", "--stdio" },
					filetypes = { "json", "jsonc" },
					root_dir = require("lspconfig.util").root_pattern(".git"),
				},
				yamlls = {
					capabilities = capabilities,
					cmd = { "yaml-language-server", "--stdio" },
					filetypes = { "yaml", "yaml.docker-compose" },
					root_dir = require("lspconfig.util").root_pattern(".git"),
				},
				lua_ls = {
					capabilities = capabilities,
					cmd = { "lua-language-server" },
					filetypes = { "lua" },
					root_dir = require("lspconfig.util").root_pattern(".git"),
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							runtime = { version = "LuaJIT" },
							workspace = {
								checkThirdParty = false,
								library = {
									"${3rd}/luv/library",
									unpack(vim.api.nvim_get_runtime_file("", true)),
								},
							},
							diagnostics = { disable = { "missing-fields" } },
							format = {
								enable = false,
							},
							-- Enable semantic tokens for Lua
							semantic = {
								enable = true,
								annotations = true,
								variables = true,
							},
						},
					},
				},
			}

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
			local ensure_installed = {}
			for server_name, _ in pairs(servers) do
				table.insert(ensure_installed, server_name)
			end

			-- Add other tools explicitly
			table.insert(ensure_installed, "stylua")

			-- Setup the mason-tool-installer with the list we built
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
									staticcheck = true,
									hints = {
										assignVariableTypes = true,
										compositeLiteralFields = true,
										compositeLiteralTypes = true,
										constantValues = true,
										functionTypeParameters = true,
										parameterNames = true,
										rangeVariableTypes = true,
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
