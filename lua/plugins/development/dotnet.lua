return {
	"seblyng/roslyn.nvim",
	ft = { "cs" },
	dependencies = { "neovim/nvim-lspconfig", "williamboman/mason.nvim" },
	cmd = {
		"Roslyn",
		"DotnetProject",
		"DotnetBuild",
		"DotnetRun",
		"DotnetWatch",
		"DotnetTest",
		"DotnetRestore",
		"DotnetFormat",
		"DotnetDebug",
		"DotnetAttach",
		"DotnetTools",
	},
	keys = {
		{ "<leader>np", "<cmd>DotnetProject<cr>", desc = ".NET select startup project" },
		{ "<leader>nb", "<cmd>DotnetBuild<cr>", desc = ".NET build" },
		{ "<leader>nr", "<cmd>DotnetRun<cr>", desc = ".NET run" },
		{ "<leader>nw", "<cmd>DotnetWatch<cr>", desc = ".NET watch" },
		{ "<leader>nt", "<cmd>DotnetTest<cr>", desc = ".NET test" },
		{ "<leader>na", "<cmd>DotnetAttach<cr>", desc = ".NET attach debugger" },
	},
	config = function()
		vim.lsp.config("roslyn", {
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
			settings = {
				["csharp|completion"] = {
					dotnet_show_completion_items_from_unimported_namespaces = true,
				},
				["csharp|inlay_hints"] = {
					csharp_enable_inlay_hints_for_implicit_variable_types = true,
					csharp_enable_inlay_hints_for_implicit_object_creation = true,
				},
				["csharp|formatting"] = { dotnet_organize_imports_on_format = true },
			},
		})
		require("roslyn").setup({ broad_search = true })
		require("core.dotnet").setup_commands()
		require("core.roslyn").setup()
	end,
}
