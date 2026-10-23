-- Run: nvim --headless -u NONE -l tests/project_languages.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local root = vim.fn.tempname()
local function file(name, content)
	local path = root .. "/" .. name
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile({ content or "" }, path)
	return path
end
local function check()
	file(".git/HEAD", "ref: refs/heads/main")
	file("App.csproj", "<Project />")
	file("wwwroot/lib/legacy.php")
	file("wwwroot/lib/widget.ts")
	file("obj/generated/package.json", "{}")
	file("appsettings.json", "{}")
	vim.cmd.cd(root)
	local languages = require("core.project_languages")
	languages.setup()
	assert(vim.wait(5000, function()
		local project = languages.projects[languages.root(root)]
		return project and project.scanned
	end), "project scan timed out")
	local project = languages.projects[languages.root(root)]
	assert(project.languages.cs, "C# manifest was not detected")
	assert(not project.languages.php, "unopened bundled PHP selected PHP tools")
	assert(not project.languages.typescript, "unopened bundled TypeScript selected TS tools")
	assert(not project.languages.javascript, "build output selected JavaScript tools")
	assert(not project.languages.json, "incidental JSON selected JSON tools")
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, root .. "/wwwroot/lib/widget.ts")
	vim.bo[buf].filetype = "typescript"
	languages.refresh()
	assert(project.languages.typescript, "opening TypeScript did not select its tooling")
	vim.api.nvim_buf_delete(buf, { force = true })
	languages.refresh()
	assert(not project.languages.typescript, "closed file kept unrelated tooling active")
	file("frontend/package.json", '{"dependencies":{"vue":"*"}}')
	languages.refresh(true)
	assert(vim.wait(5000, function() return project.scanned end), "refresh timed out")
	assert(project.languages.javascript and project.languages.vue, "mixed project manifests were missed")
	print("PASS: C# isolation, ignored build output, buffer lifecycle, mixed-project manifests")
end
local ok, err = xpcall(check, debug.traceback)
vim.fn.delete(root, "rf")
if not ok then error(err) end
