return {
	{
		"stevearc/conform.nvim",
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			require("mason").setup()
			local registry = require("mason-registry")

			local tools = {
				-- Formatters
				"stylua",
				"black",
				"prettier",
				"shfmt",
				"clang-format",
				"rustfmt",
				"gofumpt",

				-- Debuggers / DAP
				"codelldb",
				"cpptools",
				"delve",
				"debugpy",
				"js-debug-adapter",
				"node-debug2-adapter",
				"go-debug-adapter",

				-- Linters (optional)
				"eslint_d",
				"shellcheck",
			}

			-- Ensure tools are installed
			local function ensure_installed(tool_list)
				for _, name in ipairs(tool_list) do
					local ok, pkg = pcall(registry.get_package, name)
					if ok and not pkg:is_installed() then
						pkg:install()
						vim.notify("Installing " .. name, vim.log.levels.INFO)
					end
				end
			end

			-- Refresh registry and install
			if registry.refresh then
				registry.refresh(function()
					ensure_installed(tools)
				end)
			else
				ensure_installed(tools)
			end

			-- Configure conform.nvim
			require("conform").setup({
				format_on_save = {
					lsp_fallback = true,
					async = true,
				},
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					go = { "gofumpt" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					html = { "prettier" },
					css = { "prettier" },
					sh = { "shfmt" },
					rust = { "rustfmt" },
					c = { "clang-format" },
					cpp = { "clang-format" },
				},
				formatters = {
					black = {
						prepend_args = { "--fast" },
					},
					prettier = {
						prepend_args = { "--tab-width", "2" },
					},
				},
			})
		end,
	},
}
