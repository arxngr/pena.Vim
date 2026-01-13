-- lsp/servers/phpactor.lua
local M = {}
M.opts = {
	settings = {
		phpactor = {
			files = {
				maxSize = 5000000,
			},
			completion = {
				insertUseDeclaration = true,
			},
			navigation = {
				includeGlobals = false,
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
