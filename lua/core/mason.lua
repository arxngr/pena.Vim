local M = {}

function M.is_installing(pkg)
	return pkg:get_handle()
		:map(function(handle)
			return not handle:is_closed()
		end)
		:or_else(false)
end

function M.setup()
	if M.configured then
		return
	end
	require("mason").setup({
		registries = { "github:mason-org/mason-registry", "github:Crashdummyy/mason-registry" },
		ui = { icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
		log_level = vim.log.levels.WARN,
		max_concurrent_installers = 2,
	})
	M.configured = true
end

return M
