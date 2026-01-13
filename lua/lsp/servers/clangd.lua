-- lsp/servers/clangd.lua
local M = {}
M.opts = {
	capabilities = {
		offsetEncoding = { "utf-16" },
	},
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
		"--pch-storage=memory",
		"--enable-config",
	},
	init_options = {
		usePlaceholders = true,
		completeUnimported = true,
		clangdFileStatus = true,
	},
	on_attach = function(client, bufnr)
		-- Clangd usually has semantic tokens, but enforce it
		if client.server_capabilities.semanticTokensProvider == nil then
			client.server_capabilities.semanticTokensProvider = {
				full = true,
				legend = {
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
				},
				range = true,
			}
		end
	end,
}
return M
