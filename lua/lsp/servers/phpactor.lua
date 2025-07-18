return {
	settings = {
		phpactor = {
			files = {
				maxSize = 5000000, -- 5MB limit to prevent memory issues
			},
			completion = {
				insertUseDeclaration = true,
			},
			navigation = {
				includeGlobals = false,
			},
		},
	},
}
