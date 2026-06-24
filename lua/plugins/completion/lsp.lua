return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", version = "^1.0.0" },
			{ "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"hrsh7th/nvim-cmp",
			"hrsh7th/cmp-nvim-lsp",
		},
		opts = {
			inlay_hints = { enabled = true, exclude = { "vue" } },
			codelens = { enabled = false },
		},
		config = function()
			vim.lsp.log.set_level("ERROR")

			-- truncate lsp.log on startup if it exceeds 10 MB
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					local log = vim.fn.stdpath("state") .. "/lsp.log"
					if vim.fn.getfsize(log) > 10 * 1024 * 1024 then
						vim.fn.writefile({}, log)
					end
				end,
			})

			-- diagnostic config
			vim.diagnostic.config({
				virtual_text = true,
				signs = true,
				update_in_insert = true,
				severity_sort = true,
			})

			-- base capabilities (snippet support + cmp)
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
				config = config or {}
				config.border = "rounded"
				return vim.lsp.handlers.hover(err, result, ctx, config)
			end

			vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
				config = config or {}
				config.border = "rounded"
				return vim.lsp.handlers.signature_help(err, result, ctx, config)
			end

			-- keymaps for LSP
			local function setup_lsp_keymaps(bufnr)
				local map = function(keys, func, desc, mode)
					mode = mode or "n"
					vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
				end

				map("<leader>rn", vim.lsp.buf.rename, "Rename")
				map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
				map("gD", function()
					local ok, snacks = pcall(require, "snacks")
					if ok and snacks.picker then
						snacks.picker.lsp_declarations()
					else
						vim.lsp.buf.declaration()
					end
				end, "Goto Declaration")

				map("gd", function()
					local ok, snacks = pcall(require, "snacks")
					if ok and snacks.picker then
						snacks.picker.lsp_definitions()
					else
						vim.lsp.buf.definition()
					end
				end, "Goto Definition")

				map("gr", function()
					local ok, snacks = pcall(require, "snacks")
					if ok and snacks.picker then
						snacks.picker.lsp_references()
					else
						vim.lsp.buf.references()
					end
				end, "References")

				map("gi", function()
					local ok, snacks = pcall(require, "snacks")
					if ok and snacks.picker then
						snacks.picker.lsp_implementations()
					else
						vim.lsp.buf.implementation()
					end
				end, "Goto Implementation")
			end

			-- LSP attach autocmd
			local inlay_hints_enabled = false

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
				callback = function(event)
					local bufnr = event.buf
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end
					setup_lsp_keymaps(bufnr)

					-- Enable inlay hints if supported (respects global state)
					if client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
						vim.lsp.inlay_hint.enable(inlay_hints_enabled, { bufnr = bufnr })
					end

					-- Global inlay hints toggle keymap (only set once)
					if not vim.g.inlay_hint_keymap_set then
						vim.keymap.set("n", "<leader>uh", function()
							if not vim.lsp.inlay_hint then
								return
							end
							-- Toggle global state
							inlay_hints_enabled = not inlay_hints_enabled

							-- Apply to all loaded buffers
							for _, buf in ipairs(vim.api.nvim_list_bufs()) do
								if vim.api.nvim_buf_is_loaded(buf) then
									vim.lsp.inlay_hint.enable(inlay_hints_enabled, { bufnr = buf })
								end
							end

							-- Print status
							if inlay_hints_enabled then
								vim.notify("Inlay hints enabled", vim.log.levels.INFO)
							else
								vim.notify("Inlay hints disabled", vim.log.levels.INFO)
							end
						end, { desc = "Toggle Inlay Hints (Global)" })
						vim.g.inlay_hint_keymap_set = true
					end

					-- navic symbols
					if client.server_capabilities.documentSymbolProvider then
						local ok, navic = pcall(require, "nvim-navic")
						if ok then
							navic.attach(client, bufnr)
						end
					end
				end,
			})

			-- Mason setup
			require("mason").setup({
				ui = {
					icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
				},
				log_level = vim.log.levels.WARN,
				max_concurrent_installers = 2,
			})

			-- Required runtime per tool. Tools not listed have no check (Mason fetches a prebuilt binary).
			-- clangd, lua_ls, marksman, stylua → prebuilt; no runtime needed to install.
			local tool_dependencies = {
				-- Go
				gopls         = "go",
				sqls          = "go",
				-- Python
				pyright       = "python3",
				-- PHP
				phpactor      = "php",
				-- Rust
				rust_analyzer = "cargo",
				-- Node (npm-based LSPs)
				ts_ls         = "node",
				jsonls        = "node",
				yamlls        = "node",
				cssls         = "node",
				html          = "node",
				bashls        = "node",
				dockerls      = "node",
			}

			local tools_to_check = {
				"gopls",
				"pyright",
				"clangd",
				"html",
				"cssls",
				"phpactor",
				"stylua",
				"ts_ls",
				"jsonls",
				"yamlls",
				"marksman",
				"rust_analyzer",
				"bashls",
				"lua_ls",
				"sqls",
				"dockerls",
			}

			-- persist which warnings have already been shown so they don't repeat every startup
			local warned_file = vim.fn.stdpath("state") .. "/mason_dep_warned.json"
			local warned = {}
			local rf_ok, rf_data = pcall(vim.fn.readfile, warned_file)
			if rf_ok and rf_data[1] then
				local jd_ok, decoded = pcall(vim.fn.json_decode, table.concat(rf_data, ""))
				if jd_ok and type(decoded) == "table" then warned = decoded end
			end

			local ensure_installed = {}
			local dirty = false
			for _, tool in ipairs(tools_to_check) do
				local dep = tool_dependencies[tool]
				if dep then
					if vim.fn.executable(dep) == 1 then
						table.insert(ensure_installed, tool)
					elseif not warned[tool] then
						vim.notify(
							string.format("Mason: skipping '%s' ('%s' not found in PATH)", tool, dep),
							vim.log.levels.WARN
						)
						warned[tool] = true
						dirty = true
					end
				else
					table.insert(ensure_installed, tool)
				end
			end

			if dirty then
				pcall(vim.fn.writefile, { vim.fn.json_encode(warned) }, warned_file)
			end

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
				auto_update = false,
				run_on_start = true,
			})

			-- load server configs from lsp/servers/*.lua
			local function load_server_config(name)
				local ok, config = pcall(require, "lsp.servers." .. name)
				if ok and type(config) == "table" then
					return config.opts or {}
				end
				return {}
			end

			-- setup each LSP server using mason-lspconfig handlers
			require("mason-lspconfig").setup({
				automatic_installation = true,
				handlers = {
					function(server_name)
						local server_config = load_server_config(server_name)

						-- merge capabilities
						server_config.capabilities =
							vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})

						-- default flags
						server_config.flags = server_config.flags or {}
						server_config.flags.debounce_text_changes = server_config.flags.debounce_text_changes or 300

						-- use on_attach if defined
						if server_config.on_attach then
							local user_on_attach = server_config.on_attach
							server_config.on_attach = function(client, bufnr)
								user_on_attach(client, bufnr)
							end
						end

						vim.lsp.config(server_name, server_config)
						vim.lsp.enable({ server_name })
					end,
				},
			})
		end,
	},
}
