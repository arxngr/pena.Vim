return {
	capabilities = {
		offsetEncoding = { "utf-16" },
	},
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders=0",
		"--fallback-style=llvm",
		"--malloc-trim", -- Help with memory usage
		"--pch-storage=memory", -- Store PCH in memory for faster access
	},
	init_options = {
		usePlaceholders = false,
		completeUnimported = true,
		clangdFileStatus = true,
	},
}
