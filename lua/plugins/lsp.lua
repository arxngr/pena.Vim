return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", version = "^1.0.0" },
			{ "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
		},
		opts = function()
			return {
				inlay_hints = {
					enabled = true,
					exclude = { "vue" },
				},
				codelens = {
					enabled = false,
				},
				capabilities = {
					workspace = {
						fileOperations = {
							didRename = true,
							willRename = true,
						},
					},
				},
			}
		end,
		config = function()
			vim.diagnostic.config({
				virtual_lines = {
					format = function(d)
						return d.message:gsub("\n", " "):sub(1, 999)
					end,
				},
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local on_attach = function(client, bufnr)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
				end

				map("gd", require("telescope.builtin").lsp_definitions, "Goto Definition")
				map("gr", require("telescope.builtin").lsp_references, "Goto References")
				map("gI", require("telescope.builtin").lsp_implementations, "Goto Implementation")
				map("gt", require("telescope.builtin").lsp_type_definitions, "Type Definition")
				map("<leader>gs", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace Symbols")
				map("<leader>rn", vim.lsp.buf.rename, "Rename")
				map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
				map("gD", vim.lsp.buf.declaration, "Goto Declaration")

				if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
					map("<leader>uh", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
					end, "Toggle Inlay Hints")
				end

				if client and client.server_capabilities.documentSymbolProvider then
					local ok, navic = pcall(require, "nvim-navic")
					if ok then
						navic.attach(client, bufnr)
					end
				end
			end

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

			local ensure_installed = {
				"gopls",
				"clangd",
				"pyright",
				"vtsls",
				"html",
				"cssls",
				"phpactor",
			}

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
				auto_update = false,
				run_on_start = true,
			})

			require("mason-lspconfig").setup({
				ensure_installed = ensure_installed,
			})

			local lspconfig = require("lspconfig")
			require("mason-lspconfig").setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						on_attach = on_attach,
						capabilities = capabilities,
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
