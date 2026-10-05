local M = {}

function M.read_json(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return {}
	end
	local available, json = pcall(require, "overseer.json")
	local decoded, data = pcall(available and json.decode or vim.json.decode, table.concat(lines, "\n"))
	return decoded and type(data) == "table" and data or {}
end

local function get(data, name)
	for key, value in pairs(type(data) == "table" and data or {}) do
		if key:lower() == name:lower() then
			return value
		end
	end
end

local function local_url(url)
	return url:gsub("/$", ""):gsub("://0%.0%.0%.0", "://localhost")
		:gsub("://%[::%]", "://localhost"):gsub("://%*", "://localhost"):gsub("://%+", "://localhost")
end

-- Console startup messages may be filtered or sent to a remote log sink.
-- Resolve standard configuration as fallback candidates, without changing it.
function M.configured_urls(project, profile, launch_env)
	profile = profile or {}
	local env = vim.tbl_extend("force", vim.fn.environ(), profile.environmentVariables or {}, launch_env or {})
	local settings = {}
	if project then
		local directory = vim.fs.dirname(project)
		settings = M.read_json(vim.fs.joinpath(directory, "appsettings.json"))
		local environment = env.DOTNET_ENVIRONMENT or env.ASPNETCORE_ENVIRONMENT or "Production"
		settings = vim.tbl_deep_extend("force", settings,
			M.read_json(vim.fs.joinpath(directory, "appsettings." .. environment .. ".json")))
	end
	local endpoints = {}
	for name, endpoint in pairs(get(get(settings, "Kestrel"), "Endpoints") or {}) do
		endpoints[name:lower()] = get(endpoint, "Url")
	end
	for key, value in pairs(env) do
		local name = key:lower():match("^kestrel__endpoints__(.-)__url$")
		if name then
			endpoints[name] = value
		end
	end
	local urls, seen = {}, {}
	local function add(value)
		for _, url in ipairs(vim.split(value or "", ";", { trimempty = true })) do
			url = local_url(vim.trim(url))
			if url:match("^https?://") and not seen[url] then
				seen[url] = true
				table.insert(urls, url)
			end
		end
	end
	for _, name in ipairs(vim.tbl_keys(endpoints)) do
		add(endpoints[name])
	end
	if #urls == 0 then
		add(env.URLS or env.ASPNETCORE_URLS or env.DOTNET_URLS or profile.applicationUrl or get(settings, "Urls"))
		if #urls == 0 then
			for _, scheme in ipairs({ "http", "https" }) do
				local key = scheme:upper() .. "_PORTS"
				local ports = env[key] or env["ASPNETCORE_" .. key] or env["DOTNET_" .. key]
				for _, port in ipairs(vim.split(ports or "", ";", { trimempty = true })) do
					if port:match("^%d+$") then
						add(scheme .. "://localhost:" .. port)
					end
				end
			end
		end
		if #urls == 0 and project then
			local ok, lines = pcall(vim.fn.readfile, project)
			if ok and table.concat(lines, "\n"):find("Microsoft.NET.Sdk.Web", 1, true) then
				add("http://localhost:5000") -- ASP.NET Core's default when no addresses are configured.
			end
		end
	end
	for _, url in ipairs(vim.g.dotnet_swagger_urls or {}) do
		add(url)
	end
	return urls
end

function M.new(profile, project, launch_env)
	profile = profile or {}
	local state = { active = true, opened = false, seen = {}, pending = "", processes = {} }
	local curl = vim.fn.has("win32") == 1 and "curl.exe" or "curl"
	local enabled = profile.launchBrowser ~= false and vim.g.dotnet_auto_open_swagger ~= false
	local warned = false
	local deadline = vim.uv.now() + (vim.g.dotnet_swagger_timeout_ms or 120000)

	function state:stop()
		self.active = false
		for process in pairs(self.processes) do
			pcall(process.kill, process, 15)
		end
	end

	local function probe(base, paths, index, attempt, responding)
		if not state.active or state.opened or vim.uv.now() >= deadline then
			return
		end
		local path = paths[index]
		local url = path:match("^https?://") and path or base .. "/" .. path:gsub("^/+", "")
		local process
		process = vim.system({ curl, "-sS", "-f", "-L", "-k", "--max-time", "2", url }, { text = true }, function(result)
			vim.schedule(function()
				state.processes[process] = nil
				if not state.active or state.opened then
					return
				end
				local html = (result.stdout or ""):lower()
				responding = responding or result.code == 0 or result.code == 22
				if result.code == 0 and (html:find("swaggeruibundle", 1, true) or html:find("swagger-ui", 1, true)) then
					state.opened = true
					local _, err = vim.ui.open(url)
					if err then
						vim.notify("Could not open Swagger: " .. tostring(err), vim.log.levels.WARN, { title = ".NET" })
					end
				elseif index < #paths then
					probe(base, paths, index + 1, attempt, responding)
				elseif not responding then
					vim.defer_fn(function()
						probe(base, paths, 1, attempt + 1)
					end, 2000)
				end
			end)
		end)
		state.processes[process] = true
	end

	function state:discover(base)
		if not enabled or not self.active or self.opened then
			return
		end
		base = local_url(base)
		if self.seen[base] then
			return
		end
		self.seen[base] = true
		if vim.fn.executable(curl) ~= 1 then
			if not warned then
				warned = true
				vim.notify("Install curl to open Swagger automatically.", vim.log.levels.WARN, { title = ".NET" })
			end
			return
		end
		local paths, added = {}, {}
		local function add(path)
			if type(path) == "string" and not added[path] then
				added[path] = true
				table.insert(paths, path)
			end
		end
		add(profile.launchUrl)
		for _, path in ipairs(vim.g.dotnet_swagger_paths or { "/swagger/index.html", "/swagger", "/" }) do
			add(path)
		end
		if #paths > 0 then
			vim.defer_fn(function()
				probe(base, paths, 1, 1)
			end, 500)
		end
	end

	function state:lines(lines)
		for _, line in ipairs(lines) do
			line = line:gsub("\27%[[%d;]*m", ""):gsub("\r", "")
			local base = line:match("Now listening on:%s*(https?://[^%s]+)")
			if base then
				self:discover(base)
			end
		end
	end

	-- DAP output events can split one startup line across several messages.
	function state:feed(text)
		self.pending = self.pending .. (text or "")
		while true do
			local newline = self.pending:find("\n", 1, true)
			if not newline then
				break
			end
			self:lines({ self.pending:sub(1, newline - 1) })
			self.pending = self.pending:sub(newline + 1)
		end
	end

	-- integratedTerminal sends output to a terminal buffer instead of DAP events.
	function state:watch_terminal(get_buffer)
		local function poll()
			if not enabled or not self.active or self.opened then
				return
			end
			local buffer = get_buffer()
			if buffer and vim.api.nvim_buf_is_valid(buffer) then
				local count = vim.api.nvim_buf_line_count(buffer)
				self:lines(vim.api.nvim_buf_get_lines(buffer, math.max(0, count - 200), count, false))
			end
			vim.defer_fn(poll, 300)
		end
		poll()
	end

	if enabled then
		for _, url in ipairs(M.configured_urls(project, profile, launch_env)) do
			state:discover(url)
		end
	end
	return state
end

return M
