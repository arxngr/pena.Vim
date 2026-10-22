vim.opt.rtp:prepend(vim.fn.getcwd())
local fugitive = vim.env.FUGITIVE_PATH or (vim.fn.stdpath("data") .. "/lazy/vim-fugitive")
assert(vim.fn.isdirectory(fugitive) == 1, "set FUGITIVE_PATH to the installed vim-fugitive directory")
vim.opt.rtp:prepend(fugitive)
vim.cmd("filetype plugin on")
vim.o.hidden = true
vim.g.mapleader = " "
vim.cmd("runtime plugin/fugitive.vim")
local spec = require("plugins.git.git")[2]
for _, mapping in ipairs(spec.keys) do
	vim.keymap.set("n", mapping[1], mapping[2])
end
local root = vim.fn.tempname() .. " fugitive diff fixture"
vim.fn.mkdir(root, "p")
local function git(...)
	local result = vim.system(vim.list_extend({ "git", "-C", root }, { ... }), { text = true }):wait()
	assert(result.code == 0, result.stderr)
end
local function write(name, lines) vim.fn.writefile(lines, root .. "/" .. name) end
git("init", "-q")
git("config", "user.email", "pena-test@example.invalid")
git("config", "user.name", "Pena Test")
write("source.txt", { "baseline", "cursor line", "last" })
git("add", "source.txt")
git("commit", "-qm", "fixture")
write("source.txt", { "working change", "cursor line", "last" })
local source_buf = vim.fn.bufadd(root .. "/source.txt")
vim.fn.bufload(source_buf)
vim.api.nvim_win_set_buf(0, source_buf)
vim.api.nvim_win_set_cursor(0, { 2, 2 })
local unrelated = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(unrelated, root .. "/unrelated.txt")
vim.api.nvim_buf_set_lines(unrelated, 0, -1, false, { "unsaved unrelated" })
vim.cmd("vsplit")
local unrelated_win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(unrelated_win, unrelated)
vim.api.nvim_set_current_win(vim.fn.win_findbuf(source_buf)[1])
local source_win = vim.api.nvim_get_current_win()
for index, pane in ipairs({ "source", "other", "source", "other" }) do
	if index == 3 then
		vim.api.nvim_win_close(unrelated_win, false)
		vim.o.hidden = false
	end
	local count = #vim.api.nvim_list_wins()
	vim.api.nvim_set_current_win(source_win)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>gd", true, false, true), "mx", false)
	assert(vim.wait(3000, function() return #vim.api.nvim_list_wins() == count + 1 end), "leader gd did not open Fugitive diff")
	local other
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win ~= source_win and win ~= unrelated_win then other = win end
	end
	assert(other, "missing second Fugitive pane")
	vim.api.nvim_buf_set_lines(source_buf, 0, 1, false, { "unsaved source edit" })
	local target = pane == "source" and source_win or other
	vim.api.nvim_set_current_win(target)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, false, true), "mx", false)
	assert(vim.wait(1000, function() return #vim.api.nvim_list_wins() == count end), "Ctrl-O left Fugitive diff windows")
	assert(vim.api.nvim_win_get_buf(source_win) == source_buf, "original source buffer was not restored")
	assert(vim.deep_equal(vim.api.nvim_win_get_cursor(source_win), { 2, 2 }), "original cursor was not restored")
	assert(vim.api.nvim_get_current_win() == source_win and not vim.wo[source_win].diff, "source focus or diff option not restored")
	assert(vim.bo[source_buf].modified and vim.api.nvim_buf_get_lines(source_buf, 0, 1, false)[1] == "unsaved source edit",
		"return lost unsaved source edits")
	if index < 3 then
		assert(vim.api.nvim_win_get_buf(unrelated_win) == unrelated and vim.bo[unrelated].modified,
			"unrelated modified window was not preserved")
	end
	local leaked = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match("^fugitive://") and not vim.bo[buf].modified then
			leaked[#leaked + 1] = vim.api.nvim_buf_get_name(buf)
		end
	end
	assert(#leaked == 0, "clean Fugitive temp buffers leaked: " .. table.concat(leaked, ", "))
end
vim.fn.delete(root, "rf")
print("PASS: leader gd then Ctrl-O from both Fugitive panes restores source/view, preserves unrelated edits, cleans temp buffers")
vim.cmd("qa!")
