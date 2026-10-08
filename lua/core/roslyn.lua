local M = {}

function M.enable()
	local dotnet = require("core.dotnet").ensure_dotnet()
	local dll =
		vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "roslyn", "libexec", "roslyn-language-server.dll")
	if not dotnet or vim.fn.filereadable(dll) ~= 1 then
		return false
	end
	vim.lsp.config("roslyn", { cmd = { dotnet, dll, "--stdio" } })
	require("core.project_tools").register("roslyn")
	require("core.project_tools").sync()
	return true
end

function M.install(update)
	local manager = require("core.project_tools")
	manager.attempts.roslyn = nil
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
	M.enable()
end

return M
