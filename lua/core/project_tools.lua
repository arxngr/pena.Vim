local M = { wanted = {}, servers = {}, configured_servers = {}, enabled = {}, attempts = {}, blocked = {} }
local languages = require("core.project_languages")

local runtimes = {
	pyright = "node",
	["typescript-language-server"] = "node",
	["html-lsp"] = "node",
	["css-lsp"] = "node",
	["json-lsp"] = "node",
	["yaml-language-server"] = "node",
	["bash-language-server"] = "node",
	["dockerfile-language-server"] = "node",
	["vue-language-server"] = "node",
	["svelte-language-server"] = "node",
	["astro-language-server"] = "node",
	["graphql-language-service-cli"] = "node",
	prettier = "node",
	["js-debug-adapter"] = "node",
	black = "python",
	debugpy = "python",
	djlint = "python",
	["clang-format"] = "python",
	["cmake-language-server"] = "python",
	gopls = "go",
	gofumpt = "go",
	delve = "go",
	sqls = "go",
	phpactor = "php",
	jdtls = "java",
	roslyn = "dotnet",
}

function M.runtime(name)
	if name == "dotnet" then
		return require("core.dotnet").ensure_dotnet()
	end
	if name == "python" then
		for _, candidate in ipairs({ "python3", "python", "py" }) do
			if vim.fn.executable(candidate) == 1 then
				local result = vim.system({ candidate, "--version" }, { text = true }):wait(1000)
				if result.code == 0 then
					return vim.fn.exepath(candidate)
				end
			end
		end
		return
	end
	return vim.fn.executable(name) == 1 and vim.fn.exepath(name) or nil
end

local runtime_cache = {}
local function available(package)
	local runtime = runtimes[package]
	if not runtime then
		return true
	end
	if runtime_cache[runtime] == nil then
		runtime_cache[runtime] = M.runtime(runtime) or false
	end
	if not runtime_cache[runtime] then
		M.blocked[package] = runtime
		return false
	end
	M.blocked[package] = nil
	return true
end

function M.register(server, opts)
	if M.configured_servers[server] then
		return
	end
	vim.lsp.config(server, opts or {})
	local base = vim.lsp.config[server]
	local original_root = base.root_dir
	vim.lsp.config(server, {
		root_dir = function(bufnr, on_dir)
			if not languages.supports(bufnr, server) then
				return
			end
			if type(original_root) == "function" then
				original_root(bufnr, on_dir)
			else
				on_dir(languages.for_buffer(bufnr).root)
			end
		end,
	})
	M.configured_servers[server] = true
	M.sync()
end

function M.sync(retry)
	if not M.registry_ready then
		return
	end
	local registry = require("mason-registry")
	if M.servers.vue_ls and registry.get_package("vue-language-server"):is_installed() and not M.vue_configured then
		vim.lsp.config("ts_ls", {
			filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
			init_options = {
				plugins = {
					{
						name = "@vue/typescript-plugin",
						languages = { "vue" },
						location = vim.fs.joinpath(
							vim.fn.stdpath("data"),
							"mason",
							"packages",
							"vue-language-server",
							"node_modules",
							"@vue",
							"language-server"
						),
					},
				},
			},
		})
		if M.enabled.ts_ls then
			vim.lsp.enable("ts_ls", false)
			M.enabled.ts_ls = false
		end
		M.vue_configured = true
	end
	for server, package in pairs(M.servers) do
		local ok, pkg = pcall(registry.get_package, package)
		local enable = M.configured_servers[server] and ok and pkg:is_installed() and available(package) or false
		if server == "ts_ls" and M.servers.vue_ls and not M.vue_configured then
			enable = false
		end
		if
			server == "roslyn"
			and not M.configured_servers[server]
			and ok
			and pkg:is_installed()
			and available(package)
		then
			-- Lazy-load the solution-aware plugin only when this project needs it.
			require("lazy").load({ plugins = { "roslyn.nvim" } })
			-- It may already have loaded while Mason was still installing the server.
			if not M.configured_servers[server] then
				require("core.roslyn").enable()
			end
			enable = M.configured_servers[server] and available(package) or false
		end
		if M.enabled[server] ~= enable or (enable and retry) then
			vim.lsp.enable(server, enable)
			M.enabled[server] = enable
		end
	end
	for server, enabled in pairs(M.enabled) do
		if enabled and not M.servers[server] then
			vim.lsp.enable(server, false)
			M.enabled[server] = false
		end
	end
end

function M.install_package(name, update)
	if not M.registry_ready then
		return
	end
	local registry = require("mason-registry")
	local ok, pkg = pcall(registry.get_package, name)
	if not ok then
		M.blocked[name] = "package missing from Mason registry"
		return
	end
	if not available(name) or require("core.mason").is_installing(pkg) then
		return
	end
	if pkg:is_installed() and not update then
		return
	end
	if M.attempts[name] and not update then
		return
	end
	M.attempts[name] = true
	local on_success, on_failure
	on_success = vim.schedule_wrap(function()
		pkg:off("install:failed", on_failure)
		M.sync(true)
		vim.api.nvim_exec_autocmds("User", { pattern = "ProjectToolsChanged" })
	end)
	on_failure = vim.schedule_wrap(function()
		pkg:off("install:success", on_success)
		M.blocked[name] = "installation failed; see :MasonLog"
		vim.notify(
			"Mason could not install " .. name .. ". See :MasonLog; retry with :ProjectToolsRefresh.",
			vim.log.levels.WARN
		)
	end)
	pkg:once("install:success", on_success)
	pkg:once("install:failed", on_failure)
	pkg:install()
end

local function update(projects)
	local parts = {}
	for root, project in pairs(projects) do
		local detected = vim.tbl_keys(project.languages)
		table.sort(detected)
		table.insert(parts, root .. ":" .. table.concat(detected, ","))
	end
	table.sort(parts)
	local signature = table.concat(parts, "\n")
	if M.registry_ready and M.last_signature == signature then
		return
	end
	if M.registry_ready then
		M.last_signature = signature
	end
	M.wanted = {}
	M.servers = {}
	for _, project in pairs(projects) do
		for language in pairs(project.languages) do
			local profile = languages.profiles[language]
			if profile then
				for server, package in pairs(profile.servers) do
					M.servers[server] = package
					M.wanted[package] = true
				end
				for _, package in ipairs(profile.tools) do
					M.wanted[package] = true
				end
			end
		end
	end
	for package in pairs(M.blocked) do
		if not M.wanted[package] and package ~= "tree-sitter-cli" then
			M.blocked[package] = nil
		end
	end
	if not M.registry_ready then
		return
	end
	for package in pairs(M.wanted) do
		M.install_package(package)
	end
	M.sync(true)
	vim.api.nvim_exec_autocmds("User", { pattern = "ProjectToolsChanged" })
end

function M.setup(capabilities)
	if M.configured then
		return
	end
	M.configured = true
	require("core.mason").setup()
	-- Keep Mason's UI and mappings, but never enable every previously installed server.
	require("mason-lspconfig").setup({ automatic_installation = false })
	for _, profile in pairs(languages.profiles) do
		for server in pairs(profile.servers) do
			if server ~= "roslyn" and not M.configured_servers[server] then
				local ok, config = pcall(require, "lsp.servers." .. server)
				local opts = ok and vim.deepcopy(config.opts or {}) or {}
				opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
				if server == "html" then
					opts.filetypes = { "html", "htmldjango" }
				end
				if server == "vue_ls" then
					opts.init_options = {
						typescript = {
							tsdk = vim.fs.joinpath(
								vim.fn.stdpath("data"),
								"mason",
								"packages",
								"typescript-language-server",
								"node_modules",
								"typescript",
								"lib"
							),
						},
					}
				end
				M.register(server, opts)
			end
		end
	end
	languages.subscribe(update)
	vim.api.nvim_create_user_command("ProjectTools", function()
		local parsers = package.loaded["core.project_parsers"]
		vim.notify(
			vim.inspect({
				packages = vim.tbl_keys(M.wanted),
				enabled_servers = M.enabled,
				blocked = M.blocked,
				parsers = parsers and parsers.wanted,
				parser_dependencies = parsers and parsers.blocked,
			}),
			vim.log.levels.INFO,
			{ title = "Project tools" }
		)
	end, {})
	vim.api.nvim_create_autocmd("User", {
		pattern = "ProjectToolsRefresh",
		callback = function()
			M.attempts = {}
			M.blocked = {}
			runtime_cache = {}
			M.last_signature = nil
			require("mason-registry").refresh(function()
				vim.schedule(function()
					update(languages.projects)
				end)
			end)
		end,
	})
	require("mason-registry").refresh(function()
		vim.schedule(function()
			M.registry_ready = true
			update(languages.projects)
		end)
	end)
end

return M
