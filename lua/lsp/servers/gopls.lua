return {
	settings = {
		gopls = {
			semanticTokens = true,
			usePlaceholders = false,
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
				shadow = true,
			},
			gofumpt = true,
			codelenses = {
				gc_details = false,
				generate = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
			},
			directoryFilters = {
				"-.git",
				"-.vscode",
				"-.idea",
				"-node_modules",
			},
		},
	},
}
