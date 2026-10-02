local M = {}
local selected_projects = {}
local ignored = { [".git"] = true, bin = true, obj = true, node_modules = true, packages = true }

local function notify(message)
	vim.notify(message, vim.log.levels.WARN, { title = ".NET" })
end

-- GUI applications can inherit an old PATH after Visual Studio installs the SDK.
-- Update only this Neovim process, so Mason, Roslyn, and tasks see the same host.
function M.ensure_dotnet()
	if M.dotnet_path then
		return M.dotnet_path
	end
	local windows = vim.fn.has("win32") == 1
	local executable = windows and "dotnet.exe" or "dotnet"
	local roots = {}
	local function add(root)
		if root and root ~= "" then
			table.insert(roots, root)
		end
	end
	local on_path = vim.fn.exepath("dotnet")
	if on_path ~= "" then
		add(vim.fs.dirname(vim.uv.fs_realpath(on_path) or on_path))
	end
	add(vim.env.DOTNET_ROOT)
	add(vim.env.DOTNET_ROOT_X64)
	if windows then
		for _, base in ipairs({ vim.env.ProgramW6432 or "", vim.env.ProgramFiles or "" }) do
			if base ~= "" then
				add(vim.fs.joinpath(base, "dotnet"))
			end
		end
		add("C:/Program Files/dotnet")
	end
	add(vim.fs.joinpath(vim.fn.expand("~"), ".dotnet"))
	for _, root in ipairs(roots) do
		local path = vim.fs.joinpath(root, executable)
		-- A runtime-only (often x86) host cannot build projects or restore Roslyn.
		if vim.fn.executable(path) == 1 and #vim.fn.glob(vim.fs.joinpath(root, "sdk", "*", "dotnet.dll"), false, true) > 0 then
			vim.env.PATH = root .. (windows and ";" or ":") .. (vim.env.PATH or "")
			vim.env.DOTNET_ROOT = root
			M.dotnet_path = path
			return path
		end
	end
end

local function sdk_available()
	if M.ensure_dotnet() then
		return true
	end
	notify("No .NET SDK found in PATH or standard install folders. Check :lua print(vim.env.PATH) and dotnet --list-sdks.")
	return false
end

function M.root()
	local buffer = vim.api.nvim_buf_get_name(0)
	local start = buffer ~= "" and vim.fs.dirname(buffer) or vim.fn.getcwd()
	return vim.fs.root(start, function(name)
		return name:match("%.slnx?$") ~= nil
	end) or vim.fs.root(start, ".git") or vim.fs.root(start, function(name)
		return name:match("%.csproj$") ~= nil
	end) or vim.fn.getcwd()
end

function M.projects(root)
	local projects = {}
	for name, kind in
		vim.fs.dir(root, {
			depth = math.huge,
			skip = function(path)
				return not ignored[vim.fs.basename(path)]
			end,
		})
	do
		if kind == "file" and name:match("%.csproj$") then
			table.insert(projects, vim.fs.joinpath(root, name))
		end
	end
	table.sort(projects)
	return projects
end

function M.select_project(callback, force)
	local root = M.root()
	local selected = selected_projects[root]
	if not force and selected and vim.fn.filereadable(selected) == 1 then
		callback(selected)
		return
	end
	local projects = M.projects(root)
	local function choose(project)
		if not project then
			return
		end
		selected_projects[root] = project
		callback(project)
	end
	if #projects == 0 then
		notify("No .csproj found. Open Neovim from your solution folder.")
	elseif #projects == 1 then
		choose(projects[1])
	else
		vim.ui.select(projects, {
			prompt = ".NET startup project:",
			format_item = function(path)
				return vim.fs.relpath(root, path) or path
			end,
		}, choose)
	end
end

local function save_buffers()
	local ok, err = pcall(vim.cmd, "wall")
	if not ok then
		notify("Could not save buffers: " .. err)
	end
	return ok
end

local function task(name, args, cwd, callback)
	local overseer = require("overseer")
	local job = overseer.new_task({
		name = name,
		cmd = { "dotnet" },
		args = args,
		cwd = cwd,
		-- A real terminal supports interactive console apps and dotnet watch.
		strategy = { "jobstart", use_terminal = true },
		components = { "default" },
	})
	if callback then
		job:subscribe("on_complete", function(_, status)
			vim.schedule(function()
				callback(status == "SUCCESS")
			end)
			return true -- Unsubscribe so rerunning a build does not launch another debug session.
		end)
	end
	job:start()
	overseer.open({ enter = false })
	return job
end

function M.run(action)
	if not sdk_available() or not save_buffers() then
		return
	end
	M.select_project(function(project)
		local args = { action, project }
		if action == "run" then
			args = { "run", "--project", project }
		elseif action == "watch" then
			args = { "watch", "--project", project, "run" }
		elseif action == "build" then
			args = { "build", project, "--configuration", "Debug" }
		end
		task(".NET " .. action .. ": " .. vim.fs.basename(project), args, vim.fs.dirname(project))
	end)
end

local function properties(project, framework, callback)
	local args = {
		"dotnet",
		"msbuild",
		project,
		"-nologo",
		"-verbosity:quiet",
		"-property:Configuration=Debug",
		"-getProperty:TargetPath,TargetFramework,TargetFrameworks,OutputType",
	}
	if framework then
		table.insert(args, "-property:TargetFramework=" .. framework)
	end
	vim.system(args, { text = true, cwd = vim.fs.dirname(project) }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				notify("Could not evaluate project (requires SDK 8+): " .. (result.stderr or result.stdout or ""))
				return
			end
			local ok, data = pcall(vim.json.decode, result.stdout or "")
			if not ok or type(data) ~= "table" or not data.Properties then
				notify("MSBuild did not return project properties.")
				return
			end
			callback(data.Properties)
		end)
	end)
end

local function debugger_path()
	local executable = vim.fn.exepath("netcoredbg")
	if executable ~= "" then
		return executable
	end
	local root = vim.env.MASON or vim.fs.joinpath(vim.fn.stdpath("data"), "mason")
	local relative = vim.fn.has("win32") == 1 and "netcoredbg/netcoredbg.exe" or "libexec/netcoredbg/netcoredbg"
	local path = vim.fs.joinpath(root, "packages", "netcoredbg", relative)
	if vim.fn.executable(path) == 1 then
		return path
	end
	notify("Install the debugger with :MasonInstall netcoredbg, then retry.")
end

local function launch_environment(project, callback)
	local path = vim.fs.joinpath(vim.fs.dirname(project), "Properties", "launchSettings.json")
	local ok, lines = pcall(vim.fn.readfile, path)
	local decoded, settings = false, nil
	if ok then
		decoded, settings = pcall(vim.json.decode, table.concat(lines, "\n"))
	end
	local profiles = {}
	if decoded and type(settings) == "table" and type(settings.profiles) == "table" then
		for name, profile in pairs(settings.profiles) do
			if profile.commandName == "Project" then
				table.insert(profiles, name)
			end
		end
	end
	table.sort(profiles)
	local function choose(name)
		if not name then
			return
		end
		local profile = settings.profiles[name]
		local env = vim.deepcopy(profile.environmentVariables or {})
		if profile.applicationUrl then
			env.ASPNETCORE_URLS = profile.applicationUrl
		end
		if profile.commandLineArgs and profile.commandLineArgs ~= "" then
			notify(
				"Debug launch does not parse commandLineArgs. Use a coreclr .vscode/launch.json configuration for arguments."
			)
		end
		callback(env)
	end
	if #profiles == 0 then
		callback({})
	elseif #profiles == 1 then
		choose(profiles[1])
	else
		vim.ui.select(profiles, { prompt = ".NET launch profile:" }, choose)
	end
end

function M.prepare_launch(config, callback)
	if not sdk_available() or not save_buffers() then
		return
	end
	M.select_project(function(project)
		properties(project, nil, function(props)
			local frameworks = vim.split(props.TargetFrameworks or "", ";", { trimempty = true })
			local function build(framework)
				if not framework or framework == "" then
					return
				end
				local args = { "build", project, "--configuration", "Debug", "--framework", framework }
				task(".NET debug build: " .. vim.fs.basename(project), args, vim.fs.dirname(project), function(success)
					if not success then
						notify("Build failed. Check the Overseer task output.")
						return
					end
					properties(project, framework, function(built)
						if built.OutputType ~= "Exe" and built.OutputType ~= "WinExe" then
							notify(
								"Select an executable startup project with :DotnetProject; libraries cannot be launched."
							)
							return
						end
						local path = built.TargetPath
						if not path or path == "" then
							notify("Build output DLL was not found.")
							return
						end
						if not path:match("^[/\\]") and not path:match("^%a:[/\\]") then
							path = vim.fs.joinpath(vim.fs.dirname(project), path)
						end
						if vim.fn.filereadable(path) ~= 1 then
							notify("Build output DLL was not found.")
							return
						end
						launch_environment(project, function(env)
							config.program = path
							config.cwd = vim.fs.dirname(project)
							config.env = vim.tbl_extend("force", env, config.env or {})
							config._dotnet_project_launch = nil
							callback(config)
						end)
					end)
				end)
			end
			if #frameworks > 1 then
				vim.ui.select(frameworks, { prompt = ".NET target framework:" }, build)
			else
				build(props.TargetFramework ~= "" and props.TargetFramework or frameworks[1])
			end
		end)
	end)
end

function M.setup_dap(dap)
	dap.adapters.coreclr = function(callback)
		local path = debugger_path()
		if not path then
			return
		end
		callback({
			type = "executable",
			command = path,
			args = { "--interpreter=vscode" },
			enrich_config = function(config, done)
				if config._dotnet_project_launch then
					M.prepare_launch(vim.deepcopy(config), done)
				else
					done(config)
				end
			end,
		})
	end
	dap.configurations.cs = {
		{
			name = ".NET: build and debug startup project",
			type = "coreclr",
			request = "launch",
			_dotnet_project_launch = true,
			stopAtEntry = false,
			console = "integratedTerminal",
		},
		{
			name = ".NET: attach to process",
			type = "coreclr",
			request = "attach",
			processId = require("dap.utils").pick_process,
		},
	}
end

function M.setup_commands()
	vim.api.nvim_create_user_command("DotnetProject", function()
		M.select_project(function(project)
			vim.notify(".NET startup project: " .. project)
		end, true)
	end, {})
	for _, action in ipairs({ "build", "run", "watch", "test", "restore", "format" }) do
		local command = "Dotnet" .. action:sub(1, 1):upper() .. action:sub(2)
		vim.api.nvim_create_user_command(command, function()
			M.run(action)
		end, {})
	end
	for command, index in pairs({ DotnetDebug = 1, DotnetAttach = 2 }) do
		vim.api.nvim_create_user_command(command, function()
			local dap = require("dap")
			dap.run(dap.configurations.cs[index])
		end, {})
	end
	vim.api.nvim_create_user_command("DotnetTools", function(opts)
		if not sdk_available() then
			return
		end
		require("core.roslyn").install(opts.bang)
	end, { bang = true })
end
return M
