return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", version = "^1.0.0" },
			{ "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
		},
		opts = {
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
		},
		config = function()
			vim.diagnostic.config({
				virtual_text = true,
				signs = true,
				update_in_insert = true,
				severity_sort = true,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			local function setup_lsp_keymaps(event)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				map("<leader>rn", vim.lsp.buf.rename, "Rename")
				map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
				map("gD", vim.lsp.buf.declaration, "Goto Declaration")
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					setup_lsp_keymaps(event)

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end

					-- Setup inlay hints if supported
					if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
						vim.keymap.set("n", "<leader>uh", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, { buffer = event.buf, desc = "LSP: Toggle Inlay Hints" })
					end

					-- Setup navic if available
					if client.server_capabilities.documentSymbolProvider then
						local ok, navic = pcall(require, "nvim-navic")
						if ok then
							navic.attach(client, event.buf)
						end
					end
				end,
			})

			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
				log_level = vim.log.levels.WARN,
				max_concurrent_installers = 2,
			})

			local ensure_installed = {
				"stylua",
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

			local function load_server_config(server_name)
				local ok, config = pcall(require, "lsp.servers." .. server_name)
				if ok and type(config) == "table" then
					return config
				end
				return {}
			end

			local function load_server_config(server_name)
				return {}
			end

			for _, server_name in ipairs(ensure_installed) do
				local server_config = load_server_config(server_name)

				server_config.capabilities =
					vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})

				server_config.flags = server_config.flags or {}
				server_config.flags.debounce_text_changes = server_config.flags.debounce_text_changes or 300

				vim.lsp.config(server_name, server_config)
				vim.lsp.enable({ server_name })
			end
		end,
	},
}
