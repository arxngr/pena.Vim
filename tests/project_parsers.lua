-- Run: nvim --headless -u NONE -l tests/project_parsers.lua
vim.opt.rtp = { vim.fn.getcwd(), vim.env.VIMRUNTIME }
local root = vim.fn.tempname()
local path = vim.env.PATH
local cwd = vim.fn.getcwd()
vim.fn.mkdir(root, "p")
local ok, err = xpcall(function()
	vim.fn.writefile({ "fn main() {}" }, root .. "/main.rs")
	vim.cmd.cd(root)
	vim.cmd.edit(root .. "/main.rs")
	vim.bo.filetype = "rust"
	require("core.project_languages").setup()
	-- Use the real executable lookup with no system tools in PATH.
	vim.env.PATH = root
	for _, compiler in ipairs({ "cc", "gcc", "clang", "cl", "zig" }) do
		assert(vim.fn.executable(compiler) == 0, "unexpected compiler: " .. compiler)
	end
	local parsers = require("core.project_parsers")
	parsers.update()
	assert(parsers.wanted.rust, "fixture did not request Rust syntax support")
	assert(parsers.blocked.compiler, "missing compiler was not reported")
	assert(next(parsers.attempted) == nil, "parser compilation attempted without a compiler")
	assert(not package.loaded["mason-registry"], "missing compiler unexpectedly triggered Mason")
	assert(not package.loaded["nvim-treesitter"], "missing compiler unexpectedly invoked Tree-sitter installation")
	print("PASS: no compiler skips parser installation without invoking Mason or Tree-sitter installers")
end, debug.traceback)
vim.env.PATH = path
vim.cmd.cd(cwd)
vim.fn.delete(root, "rf")
if not ok then error(err) end
