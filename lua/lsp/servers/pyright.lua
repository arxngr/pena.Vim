return {
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly", -- Changed from "workspace" to reduce memory usage
				typeCheckingMode = "basic",
				autoImportCompletions = true,
				diagnosticSeverityOverrides = {
					reportUnusedImport = "warning",
					reportUnusedFunction = "warning",
					reportUnusedVariable = "warning",
				},
			},
		},
	},
}
