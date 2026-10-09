local M = {}
local selected_projects = {}
local ignored = { [".git"] = true, bin = true, obj = true, node_modules = true, packages = true }
local launch_environment

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

local function task(name, args, cwd, callback, browser_profile, browser_project)
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
	if browser_profile then
		local browser
		job:subscribe("on_start", function()
			if browser then
				browser:stop()
			end
			browser = require("core.dotnet_browser").new(browser_profile, browser_project)
		end)
		job:subscribe("on_output_lines", function(_, lines)
			if browser then
				browser:lines(lines)
			end
		end)
		job:subscribe("on_complete", function()
			if browser then
				browser:stop()
			end
		end)
	end
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
		if action == "run" or action == "watch" then
			launch_environment(project, function(_, profile, name)
				if name then
					vim.list_extend(args, { "--launch-profile", name })
				end
				task(".NET " .. action .. ": " .. vim.fs.basename(project), args, vim.fs.dirname(project), nil, profile or {}, project)
			end)
		else
			task(".NET " .. action .. ": " .. vim.fs.basename(project), args, vim.fs.dirname(project))
		end
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
	local windows = vim.fn.has("win32") == 1
	-- Mason's Windows .CMD shim interferes with the adapter's stdin/stdout
	-- protocol. DAP must spawn the native executable directly.
	if executable ~= "" and (not windows or executable:lower():match("%.exe$")) then
		return executable
	end
	local root = vim.env.MASON or vim.fs.joinpath(vim.fn.stdpath("data"), "mason")
	local relative = windows and "netcoredbg/netcoredbg.exe" or "libexec/netcoredbg/netcoredbg"
	local path = vim.fs.joinpath(root, "packages", "netcoredbg", relative)
	if vim.fn.executable(path) == 1 then
		return path
	end
	notify("Install the debugger with :MasonInstall netcoredbg, then retry.")
end

launch_environment = function(project, callback)
	local path = vim.fs.joinpath(vim.fs.dirname(project), "Properties", "launchSettings.json")
	local settings = require("core.dotnet_browser").read_json(path)
	local profiles = {}
	if type(settings.profiles) == "table" then
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
		callback(env, profile, name)
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
						launch_environment(project, function(env, profile)
							if profile and profile.commandLineArgs and profile.commandLineArgs ~= "" then
								notify("Debug launch does not parse commandLineArgs. Use a coreclr .vscode/launch.json configuration for arguments.")
							end
							config.program = path
							config.cwd = vim.fs.dirname(project)
							config.env = vim.tbl_extend("force", env, config.env or {})
							config._dotnet_project_launch = nil
							config._dotnet_browser_project = project
							config._dotnet_browser_profile = profile and {
								launchUrl = profile.launchUrl,
								launchBrowser = profile.launchBrowser,
							} or {}
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

-- Also support ordinary coreclr launch.json configurations, which do not carry
-- the metadata added by :DotnetDebug. Locate their project from the output DLL.
function M.browser_context(config)
	local project = config._dotnet_browser_project
	if not project then
		local starts = { config.cwd or M.root() }
		if type(config.program) == "string" and not config.program:find("${", 1, true) then
			local program = config.program
			if not program:match("^[/\\]") and not program:match("^%a:[/\\]") then
				program = vim.fs.joinpath(config.cwd or vim.fn.getcwd(), program)
			end
			table.insert(starts, 1, vim.fs.dirname(program))
		end
		for _, start in ipairs(starts) do
			local root = vim.fs.root(start, function(name) return name:match("%.csproj$") ~= nil end)
			if root then
				local projects = {}
				for name, kind in vim.fs.dir(root) do
					if kind == "file" and name:match("%.csproj$") then
						table.insert(projects, vim.fs.joinpath(root, name))
					end
				end
				if #projects == 1 then
					project = projects[1]
					break
				end
			end
		end
	end
	local profile = vim.deepcopy(config._dotnet_browser_profile or {})
	if project and config.launchSettingsProfile then
		local settings = require("core.dotnet_browser").read_json(
			vim.fs.joinpath(vim.fs.dirname(project), "Properties", "launchSettings.json"))
		local selected = (settings.profiles or {})[config.launchSettingsProfile]
		if selected then
			profile.launchUrl = selected.launchUrl
			profile.launchBrowser = selected.launchBrowser
		end
	end
	for _, key in ipairs({ "launchUrl", "launchBrowser" }) do
		if config[key] ~= nil then
			profile[key] = config[key]
		end
	end
	return profile, project, config.env
end

function M.setup_dap(dap)
	local browsers = {}
	dap.listeners.before.event_initialized["dotnet_windows_source_paths"] = function(session)
		if vim.fn.has("win32") ~= 1 or session.config.type ~= "coreclr" or session._dotnet_windows_source_paths then
			return
		end
		session._dotnet_windows_source_paths = true
		local request = session.request
		-- netcoredbg matches absolute source paths exactly; Windows PDBs use backslashes.
		session.request = function(self, command, arguments, ...)
			if
				command == "setBreakpoints"
				and arguments
				and arguments.source
				and type(arguments.source.path) == "string"
			then
				arguments = vim.deepcopy(arguments)
				arguments.source.path = arguments.source.path:gsub("/", "\\")
			end
			return request(self, command, arguments, ...)
		end
	end
	dap.listeners.after.event_initialized["dotnet_swagger"] = function(session)
		if session.config.type ~= "coreclr" or session.config.request ~= "launch" then
			return
		end
		if browsers[session] then
			browsers[session]:stop()
		end
		local browser = require("core.dotnet_browser").new(M.browser_context(session.config))
		browsers[session] = browser
		browser:watch_terminal(function()
			return session.term_buf
		end)
	end
	dap.listeners.after.event_output["dotnet_swagger"] = function(session, body)
		if browsers[session] then
			browsers[session]:feed(body.output)
		end
	end
	local function stop_browser(session)
		if browsers[session] then
			browsers[session]:stop()
			browsers[session] = nil
		end
	end
	for _, event in ipairs({ "event_terminated", "event_exited", "disconnect" }) do
		dap.listeners.before[event]["dotnet_swagger"] = stop_browser
	end
	dap.adapters.coreclr = function(callback)
		-- Repair PATH before spawning the adapter, including for launch.json.
		M.ensure_dotnet()
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
