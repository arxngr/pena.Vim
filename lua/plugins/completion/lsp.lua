return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim", version = "^1.0.0" },
			{ "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
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

			require("core.project_tools").setup(capabilities)
		end,
	},
}
