local M = {}
-- Older builds can emit multiple reports for an unqualified document diagnostic pull.
-- This release includes the server's diagnostic-source aggregation fix.
local MINIMUM_VERSION = "5.13.0-1.26521.14"

local switching_target = false
local target_restarts = {}

local function select_target()
	if switching_target then
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local targets = require("roslyn.sln.discovery").find_solutions_for_buffer(bufnr)
	vim.ui.select(targets or {}, {
		prompt = "Select target solution: ",
		format_item = function(file) return vim.fn.fnamemodify(file, ":.") end,
	}, function(file)
		if not file or switching_target or not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		local client = vim.lsp.get_clients({ name = "roslyn", bufnr = bufnr })[1]
		if client and require("roslyn.store").get(client.id) == file then
			return
		end
		local config = vim.tbl_deep_extend("force", {}, vim.lsp.config.roslyn, {
			root_dir = vim.fs.dirname(file),
			on_init = function(new_client)
				require("roslyn.lsp.on_init").sln(new_client, file)
			end,
		})
		local buffers = client and vim.tbl_keys(client.attached_buffers) or { bufnr }
		local function start()
			switching_target = false
			local id
			for _, buf in ipairs(buffers) do
				if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
					if id then
						vim.lsp.buf_attach_client(buf, id)
					else
						id = vim.lsp.start(config, { bufnr = buf })
					end
				end
			end
		end
		if not client then
			start()
			return
		end
		switching_target = true
		-- Wait for this client's exit, not roslyn.nvim's global stopped event.
		target_restarts[client.id] = start
		-- The upstream target command force-kills Windows servers (exit 1, signal 15).
		client:stop()
	end)
end

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
	local on_exit = vim.lsp.config.roslyn.on_exit
	local callbacks = type(on_exit) == "function" and { on_exit } or vim.list_extend({}, on_exit or {})
	callbacks[#callbacks + 1] = function(_, _, client_id)
		local restart = target_restarts[client_id]
		target_restarts[client_id] = nil
		if restart then
			vim.schedule(restart)
		end
	end
	vim.lsp.config("roslyn", { on_exit = callbacks })
	local function register_target_command()
		vim.api.nvim_create_user_command("Roslyn", function(opts)
			if opts.fargs[1] == "target" then
				select_target()
			else
				vim.notify("Roslyn: Unknown subcommand: " .. opts.fargs[1], vim.log.levels.ERROR)
			end
		end, {
			nargs = "+",
			desc = "Interacts with Roslyn",
			complete = function() return { "target" } end,
			force = true,
		})
	end
	-- roslyn.nvim recreates its command on every C#/Razor FileType event.
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "cs", "razor" },
		callback = register_target_command,
	})
	register_target_command()
	M.enable()
end

return M
