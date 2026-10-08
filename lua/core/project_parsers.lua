local M = { attempted = {}, wanted = {}, blocked = {} }

local function start_highlighting()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
			pcall(vim.treesitter.start, bufnr)
		end
	end
end

function M.update()
	local languages = require("core.project_languages")
	M.wanted = {}
	for _, project in pairs(languages.projects) do
		for language in pairs(project.languages) do
			local profile = languages.profiles[language]
			if profile then
				for _, parser in ipairs(profile.parsers) do
					M.wanted[parser] = true
				end
			end
		end
	end
	start_highlighting()
	local missing = {}
	for parser in pairs(M.wanted) do
		if not M.attempted[parser] and #vim.api.nvim_get_runtime_file("parser/" .. parser .. ".*", false) == 0 then
			table.insert(missing, parser)
		end
	end
	if #missing == 0 then
		return
	end
	local compiler = false
	for _, name in ipairs({ "cc", "gcc", "clang", "cl", "zig" }) do
		if vim.fn.executable(name) == 1 then
			compiler = true
			break
		end
	end
	if not compiler then
		M.blocked.compiler = "C compiler unavailable"
		return
	end
	M.blocked.compiler = nil
	if not M.legacy and vim.fn.executable("tree-sitter") ~= 1 then
		M.blocked.cli = "tree-sitter CLI is being installed through Mason"
		require("core.project_tools").install_package("tree-sitter-cli")
		return
	end
	M.blocked.cli = nil
	if M.legacy then
		for _, parser in ipairs(missing) do
			if M.available[parser] then
				M.attempted[parser] = true
				vim.cmd("TSInstall " .. parser)
			end
		end
	else
		local supported = {}
		for _, parser in ipairs(missing) do
			if M.available[parser] then
				M.attempted[parser] = true
				table.insert(supported, parser)
			end
		end
		if #supported > 0 then
			require("nvim-treesitter").install(supported, { max_jobs = 2 }):await(function()
				vim.schedule(start_highlighting)
			end)
		end
	end
end

function M.setup()
	local legacy, ts = pcall(require, "nvim-treesitter.configs")
	M.legacy = legacy
	M.available = {}
	if legacy then
		ts.setup({ ensure_installed = {}, auto_install = false, highlight = { enable = true } })
		for parser in pairs(require("nvim-treesitter.parsers").get_parser_configs()) do
			M.available[parser] = true
		end
	else
		ts = require("nvim-treesitter")
		ts.setup({})
		for _, parser in ipairs(ts.get_available()) do
			M.available[parser] = true
		end
	end
	local group = vim.api.nvim_create_augroup("pena-project-parsers", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(event)
			if vim.bo[event.buf].buftype == "" then
				pcall(vim.treesitter.start, event.buf)
			end
		end,
	})
	vim.api.nvim_create_autocmd("User", { group = group, pattern = "ProjectToolsChanged", callback = M.update })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "ProjectToolsRefresh",
		callback = function()
			M.attempted = {}
			M.blocked = {}
		end,
	})
	require("core.project_languages").subscribe(M.update)
end

return M
