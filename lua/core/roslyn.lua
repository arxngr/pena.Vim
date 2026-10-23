local M = {}
-- Older builds can emit multiple reports for an unqualified document diagnostic pull.
-- This release includes the server's diagnostic-source aggregation fix.
local MINIMUM_VERSION = "5.13.0-1.26521.14"

function M.enable()
	local dotnet = require("core.dotnet").ensure_dotnet()
	local dll =
		vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "roslyn", "libexec", "roslyn-language-server.dll")
	if not dotnet or vim.fn.filereadable(dll) ~= 1 then
		return false
	end
	local manager = require("core.project_tools")
	local package = require("mason-registry").get_package("roslyn")
	if M.checking_version then return false end
	M.checking_version = true
	package:get_installed_version(function(ok, version)
		M.checking_version = false
		if not ok then
			manager.blocked.roslyn = "Cannot read installed Roslyn version: " .. tostring(version)
			return
		end
		if vim.version.lt(version, MINIMUM_VERSION) then
			manager.blocked.roslyn = "Roslyn " .. MINIMUM_VERSION .. " or newer is required for pull diagnostics"
			if manager.registry_ready and not M.upgrade_requested and not require("core.mason").is_installing(package) then
				M.upgrade_requested = true
				manager.install_package("roslyn", true, MINIMUM_VERSION)
			end
			return
		end
		manager.blocked.roslyn = nil
		vim.lsp.config("roslyn", { cmd = { dotnet, dll, "--stdio" } })
		manager.register("roslyn")
		manager.sync()
	end)
	return manager.configured_servers.roslyn == true
end

function M.install(update)
	local manager = require("core.project_tools")
	manager.attempts.roslyn = nil
	M.upgrade_requested = nil
	manager.install_package("roslyn", update)
	M.enable()
end

function M.setup()
	-- roslyn.nvim enables its default executable before this config runs.
	vim.lsp.enable("roslyn", false)
	if not require("core.dotnet").ensure_dotnet() then
		vim.notify(
			"C# language support needs a .NET SDK. No SDK was found in PATH or standard install folders.",
			vim.log.levels.WARN
		)
		return
	end
	vim.api.nvim_create_autocmd("User", {
		pattern = "ProjectToolsRefresh",
		callback = function()
			M.upgrade_requested = nil
		end,
	})
	M.enable()
end

return M
