-- lsp/servers/pyright.lua
local M = {}
M.opts = {
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
				typeCheckingMode = "basic",
				autoImportCompletions = true,
				inlayHints = {
					variableTypes = true,
					functionReturnTypes = true,
					callArgumentNames = true,
					pytestParameters = true,
				},
				diagnosticSeverityOverrides = {
					reportUnusedImport = "warning",
					reportUnusedFunction = "warning",
					reportUnusedVariable = "warning",
				},
			},
		},
	},
	on_attach = function(client, bufnr)
		-- Force enable semantic tokens
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
