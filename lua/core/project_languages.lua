local M = { projects = {}, listeners = {} }

-- Package names are Mason names; server names are native vim.lsp.config names.
M.profiles = {
	c = { servers = { clangd = "clangd" }, tools = { "clang-format", "codelldb", "cpptools" }, parsers = { "c" } },
	cpp = { servers = { clangd = "clangd" }, tools = { "clang-format", "codelldb", "cpptools" }, parsers = { "cpp" } },
	python = { servers = { pyright = "pyright" }, tools = { "black", "debugpy" }, parsers = { "python" } },
	javascript = {
		servers = { ts_ls = "typescript-language-server" },
		tools = { "prettier", "js-debug-adapter" },
		parsers = { "javascript" },
	},
	typescript = {
		servers = { ts_ls = "typescript-language-server" },
		tools = { "prettier", "js-debug-adapter" },
		parsers = { "typescript", "tsx" },
	},
	html = { servers = { html = "html-lsp" }, tools = { "prettier" }, parsers = { "html", "javascript", "css" } },
	css = { servers = { cssls = "css-lsp" }, tools = { "prettier" }, parsers = { "css" } },
	django = { servers = { html = "html-lsp" }, tools = { "djlint" }, parsers = { "html" } },
	cs = { servers = { roslyn = "roslyn" }, tools = { "netcoredbg" }, parsers = { "c_sharp" } },
	go = { servers = { gopls = "gopls" }, tools = { "gofumpt", "delve" }, parsers = { "go" } },
	rust = { servers = { rust_analyzer = "rust-analyzer" }, tools = { "codelldb" }, parsers = { "rust" } },
	lua = { servers = { lua_ls = "lua-language-server" }, tools = { "stylua" }, parsers = { "lua" } },
	php = { servers = { phpactor = "phpactor" }, tools = {}, parsers = { "php", "html" } },
	sh = { servers = { bashls = "bash-language-server" }, tools = { "shfmt", "shellcheck" }, parsers = { "bash" } },
	json = { servers = { jsonls = "json-lsp" }, tools = { "prettier" }, parsers = { "json" } },
	yaml = { servers = { yamlls = "yaml-language-server" }, tools = { "prettier" }, parsers = { "yaml" } },
	markdown = {
		servers = { marksman = "marksman" },
		tools = { "prettier" },
		parsers = { "markdown", "markdown_inline" },
	},
	sql = { servers = { sqls = "sqls" }, tools = {}, parsers = { "sql" } },
	dockerfile = { servers = { dockerls = "dockerfile-language-server" }, tools = {}, parsers = { "dockerfile" } },
	terraform = { servers = { terraformls = "terraform-ls" }, tools = {}, parsers = { "terraform", "hcl" } },
	java = { servers = { jdtls = "jdtls" }, tools = {}, parsers = { "java" } },
	vue = {
		servers = { vue_ls = "vue-language-server", ts_ls = "typescript-language-server" },
		tools = { "prettier" },
		parsers = { "vue", "javascript", "typescript", "css" },
	},
	svelte = {
		servers = { svelte = "svelte-language-server" },
		tools = { "prettier" },
		parsers = { "svelte", "javascript", "typescript", "css" },
	},
	astro = {
		servers = { astro = "astro-language-server" },
		tools = { "prettier" },
		parsers = { "astro", "javascript", "typescript", "css" },
	},
	toml = { servers = { taplo = "taplo" }, tools = {}, parsers = { "toml" } },
	cmake = { servers = { cmake = "cmake-language-server" }, tools = {}, parsers = { "cmake" } },
	make = { servers = {}, tools = {}, parsers = { "make" } },
	vim = { servers = {}, tools = {}, parsers = { "vim", "vimdoc" } },
	graphql = {
		servers = { graphql = "graphql-language-service-cli" },
		tools = { "prettier" },
		parsers = { "graphql" },
	},
}

local extensions = {
	c = "c",
	h = "c",
	cc = "cpp",
	cpp = "cpp",
	cxx = "cpp",
	hpp = "cpp",
	hh = "cpp",
	hxx = "cpp",
	py = "python",
	pyi = "python",
	js = "javascript",
	jsx = "javascript",
	mjs = "javascript",
	cjs = "javascript",
	ts = "typescript",
	tsx = "typescript",
	mts = "typescript",
	cts = "typescript",
	html = "html",
	htm = "html",
	css = "css",
	scss = "css",
	less = "css",
	cs = "cs",
	csproj = "cs",
	razor = "cs",
	cshtml = "cs",
	go = "go",
	rs = "rust",
	lua = "lua",
	php = "php",
	sh = "sh",
	bash = "sh",
	zsh = "sh",
	json = "json",
	jsonc = "json",
	yaml = "yaml",
	yml = "yaml",
	md = "markdown",
	mdx = "markdown",
	sql = "sql",
	tf = "terraform",
	tfvars = "terraform",
	java = "java",
	vue = "vue",
	svelte = "svelte",
	astro = "astro",
	toml = "toml",
	cmake = "cmake",
	vim = "vim",
	graphql = "graphql",
	gql = "graphql",
}
local filetypes = {
	javascriptreact = "javascript",
	typescriptreact = "typescript",
	htmldjango = "django",
	scss = "css",
	less = "css",
	bash = "sh",
	zsh = "sh",
	dosbatch = false,
}
local manifests = {
	["package.json"] = "javascript",
	["tsconfig.json"] = "typescript",
	["jsconfig.json"] = "javascript",
	["pyproject.toml"] = "python",
	["requirements.txt"] = "python",
	["setup.py"] = "python",
	["Pipfile"] = "python",
	["go.mod"] = "go",
	["Cargo.toml"] = "rust",
	["composer.json"] = "php",
	["pom.xml"] = "java",
	["build.gradle"] = "java",
	["CMakeLists.txt"] = "cmake",
	["Makefile"] = "make",
	["Dockerfile"] = "dockerfile",
	[".luarc.json"] = "lua",
}
local ignored = {
	[".git"] = true,
	[".hg"] = true,
	[".svn"] = true,
	node_modules = true,
	vendor = true,
	bin = true,
	obj = true,
	dist = true,
	build = true,
	target = true,
	coverage = true,
	[".venv"] = true,
	venv = true,
	[".env"] = true,
	["__pycache__"] = true,
	[".next"] = true,
	[".nuxt"] = true,
	[".tox"] = true,
	[".mypy_cache"] = true,
	[".pytest_cache"] = true,
}

local function normalize(path)
	return vim.fs.normalize(vim.uv.fs_realpath(path) or path)
end

function M.root(path)
	path = path and path ~= "" and path or vim.fn.getcwd()
	local stat = vim.uv.fs_stat(path)
	local start = stat and stat.type == "directory" and path or vim.fs.dirname(path)
	local root = vim.fs.root(start, { ".git", ".hg" })
		or vim.fs.root(start, function(name)
			return name:match("%.slnx?$") ~= nil
		end)
		or vim.fs.root(start, function(name)
			return manifests[name] ~= nil or name:match("%.csproj$") ~= nil
		end)
		or start
	return normalize(root)
end

local function read(path)
	local ok, lines = pcall(vim.fn.readfile, path, "", 200)
	return ok and table.concat(lines, "\n") or ""
end

local function detect(project, path)
	local name = vim.fs.basename(path)
	local language = manifests[name] or extensions[name:match("%.([^%.]+)$") or ""]
	if name:match("^Dockerfile[%.]?") then
		language = "dockerfile"
	end
	if language then
		project.languages[language] = true
	end
	if name:match("%.slnx?$") then
		project.languages.cs = true
	end
	if name == "manage.py" or name == "pyproject.toml" or name == "Pipfile" or name:match("^requirements.*%.txt$") then
		if read(path):lower():find("django", 1, true) then
			project.languages.python = true
			project.languages.django = true
		end
	end
	if name == "package.json" then
		local content = read(path)
		for _, framework in ipairs({ "vue", "svelte", "astro" }) do
			if content:find('"' .. framework .. '"', 1, true) then
				project.languages[framework] = true
			end
		end
	end
end

local function emit()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype == "html" then
			local path = vim.api.nvim_buf_get_name(bufnr)
			local project = M.projects[M.root(path)]
			if project and project.languages.django and path:gsub("\\", "/"):find("/templates/", 1, true) then
				vim.bo[bufnr].filetype = "htmldjango"
			end
		end
	end
	for _, listener in ipairs(M.listeners) do
		listener(M.projects)
	end
end

local function scan(project)
	if project.scanning then
		return
	end
	project.scanning = true
	local iterator = vim.fs.dir(project.root, {
		depth = 25,
		skip = function(path)
			return not ignored[vim.fs.basename(path)]
		end,
	})
	local count = 0
	local function step()
		for _ = 1, 200 do
			local name, kind = iterator()
			if not name or count >= 50000 then
				project.scanning = false
				project.scanned = true
				project.truncated = name ~= nil
				emit()
				return
			end
			count = count + 1
			if kind == "file" then
				detect(project, vim.fs.joinpath(project.root, name))
			end
		end
		vim.schedule(step)
	end
	vim.schedule(step)
end

function M.for_buffer(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	return M.projects[M.root(path)]
end

function M.supports(bufnr, server)
	local project = M.for_buffer(bufnr)
	if not project then
		return false
	end
	for language in pairs(project.languages) do
		if M.profiles[language] and M.profiles[language].servers[server] then
			return true
		end
	end
	return false
end

function M.refresh(force)
	local active = {}
	local reset = {}
	local function add(path, bufnr)
		local root = M.root(path)
		local project = active[root] or M.projects[root] or { root = root, languages = {} }
		active[root] = project
		if force and not reset[root] and not project.scanning then
			project.languages = {}
			project.scanned = false
			reset[root] = true
		end
		if path and path ~= "" then
			detect(project, path)
		end
		if bufnr then
			local ft = vim.bo[bufnr].filetype
			local language = filetypes[ft] or ft
			if M.profiles[language] then
				project.languages[language] = true
			end
		end
	end
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name ~= "" then
				add(name, bufnr)
			end
		end
	end
	if next(active) == nil then
		local args = vim.fn.argv()
		if #args > 0 then
			for _, arg in ipairs(args) do
				add(vim.fn.fnamemodify(arg, ":p"))
			end
		else
			add(vim.fn.getcwd())
		end
	end
	M.projects = active
	for _, project in pairs(active) do
		if not project.scanned then
			scan(project)
		end
	end
	emit()
end

function M.subscribe(listener)
	table.insert(M.listeners, listener)
	M.setup()
	listener(M.projects)
end

function M.setup()
	if M.configured then
		return
	end
	M.configured = true
	local generation = 0
	local function refresh()
		generation = generation + 1
		local current = generation
		vim.defer_fn(function()
			if current == generation then
				M.refresh()
			end
		end, 100)
	end
	vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "BufWritePost", "BufDelete", "DirChanged" }, {
		group = vim.api.nvim_create_augroup("pena-project-languages", { clear = true }),
		callback = refresh,
	})
	vim.api.nvim_create_user_command("ProjectLanguages", function()
		vim.notify(vim.inspect(M.projects), vim.log.levels.INFO, { title = "Project languages" })
	end, {})
	vim.api.nvim_create_user_command("ProjectToolsRefresh", function()
		vim.api.nvim_exec_autocmds("User", { pattern = "ProjectToolsRefresh" })
		M.refresh(true)
	end, {})
	M.refresh()
end

return M
