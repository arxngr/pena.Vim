vim.opt.rtp:prepend(vim.fn.getcwd())
vim.cmd("filetype on")
vim.o.hidden = true
local status = require("core.git_status")
local root = vim.fn.tempname() .. " git status fixture"
vim.fn.mkdir(root, "p")
local function git(...)
	local result = vim.system(vim.list_extend({ "git", "-C", root }, { ... }), { text = true }):wait()
	assert(result.code == 0, result.stderr)
end
local function write(name, lines) vim.fn.writefile(lines, root .. "/" .. name) end
git("init", "-q")
git("config", "user.email", "pena-test@example.invalid")
git("config", "user.name", "Pena Test")
write("original.txt", { "main source", "original cursor here" })
write("base file.txt", { "committed original", "second line" })
write("staged only.txt", { "staged baseline" })
write("deleted file.txt", { "delete me" })
write("rename source.txt", { "renamed content" })
git("add", "--", ".")
git("commit", "-qm", "fixture")
local original = vim.fn.bufadd(root .. "/original.txt")
vim.fn.bufload(original)
vim.bo[original].buflisted = true
local source = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(source, original)
vim.api.nvim_win_set_cursor(source, { 2, 3 })
write("base file.txt", { "working tree version", "changed second" })
write("staged only.txt", { "staged change" })
git("add", "--", "staged only.txt")
write("untracked file.txt", { "untracked" })
vim.fn.delete(root .. "/deleted file.txt")
git("mv", "--", "rename source.txt", "renamed destination.txt")
local function enter_status()
	status.open()
	assert(vim.wait(5000, function() return vim.bo.filetype == "pena_git_status" end), "status did not open")
	return vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
end
local function select_file(win, buf, path)
	for line, text in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		if text:find(path, 1, true) then
			vim.api.nvim_win_set_cursor(win, { line, 0 })
			vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
			return
		end
	end
	error("Missing status entry: " .. path)
end
local function press(key) vim.fn.maparg(key, "n", false, true).callback() end
local function first_line(buf) return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] end
local unrelated = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(unrelated, root .. "/unrelated.txt")
vim.api.nvim_buf_set_lines(unrelated, 0, -1, false, { "unsaved unrelated" })
vim.cmd("vsplit")
local unrelated_win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(unrelated_win, unrelated)
vim.api.nvim_set_current_win(source)
local sw, sb = enter_status()
select_file(sw, sb, "base file.txt")
assert(first_line(vim.api.nvim_win_get_buf(source)) == "working tree version", "working file did not preview")
assert(vim.api.nvim_get_current_win() == sw, "preview stole list focus")
vim.api.nvim_set_current_win(source)
assert(vim.api.nvim_win_get_buf(source) == original, "leaving status did not restore source")
vim.api.nvim_set_current_win(sw)
assert(first_line(vim.api.nvim_win_get_buf(source)) == "working tree version", "returning did not resume preview")
press("q")
assert(#vim.api.nvim_list_wins() == 2 and vim.api.nvim_win_get_buf(source) == original, "cancel changed existing layout")
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(source), { 2, 3 }), "cancel lost source view")
print("PASS: path-with-spaces preview, retained list focus, leave/resume, cancel restores source/view")
local function diff_file(path, before, after, key, pane)
	local original_count = #vim.api.nvim_list_wins()
	local prior = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do prior[buf] = true end
	local win, buf = enter_status()
	select_file(win, buf, path)
	if key == "mouse" then
		vim.o.mouse = "a"
		local position = vim.api.nvim_win_get_position(source)
		vim.api.nvim_input_mouse("left", "press", "", 0, position[1], position[2] + 1)
		vim.api.nvim_input_mouse("left", "release", "", 0, position[1], position[2] + 1)
		vim.api.nvim_feedkeys(vim.keycode("<LeftMouse>"), "mx", false)
		assert(vim.wait(1000, function() return vim.wo[source].diff end), "clicking the Git preview did not open its diff")
	else
		press(key or "<CR>")
	end
	assert(#vim.api.nvim_list_wins() == original_count + 1 and vim.wo[source].diff, "selection did not open a native diff")
	local rhs = vim.api.nvim_win_get_buf(source)
	assert(first_line(rhs) == after, "wrong selected diff content for " .. path)
	local baseline
	for _, candidate in ipairs(vim.api.nvim_list_wins()) do
		if candidate ~= source and vim.wo[candidate].diff then baseline = candidate end
	end
	assert(baseline and first_line(vim.api.nvim_win_get_buf(baseline)) == before, "wrong baseline for " .. path)
	vim.api.nvim_set_current_win(pane == "source" and source or baseline)
	press("<C-o>")
	assert(#vim.api.nvim_list_wins() == original_count and vim.api.nvim_get_current_win() == source,
		"Ctrl-O failed to restore original layout/focus")
	assert(vim.api.nvim_win_get_buf(source) == original and not vim.wo[source].diff, "Ctrl-O failed to restore original buffer")
	for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
		if not prior[candidate] then
			assert(vim.bo[candidate].modified or not vim.api.nvim_buf_is_loaded(candidate), "new diff buffer leaked")
		end
	end
	assert((vim.b[original].pena_buffer_holds or 0) == 0, "Git session leaked an original-buffer hold")
end
diff_file("base file.txt", "committed original", "working tree version", nil, "source")
assert(vim.api.nvim_win_get_buf(unrelated_win) == unrelated and vim.bo[unrelated].modified, "diff restore lost unrelated split/edits")
vim.api.nvim_win_close(unrelated_win, false)
diff_file("staged only.txt", "staged baseline", "staged change", "mouse")
diff_file("untracked file.txt", "", "untracked", "<2-LeftMouse>")
diff_file("deleted file.txt", "delete me", "")
diff_file("renamed destination.txt", "renamed content", "renamed content")
print("PASS: staged, untracked, deleted, renamed diffs; Ctrl-O restores one-window source and cleans only session buffers")
sw, sb = enter_status()
select_file(sw, sb, "base file.txt")
press("<CR>")
local modified = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(modified, 0, 1, false, { "unsaved diff edits" })
press("<C-o>")
assert(vim.api.nvim_buf_is_valid(modified) and vim.bo[modified].modified and first_line(modified) == "unsaved diff edits",
	"Ctrl-O discarded unsaved working-tree changes")
assert(vim.api.nvim_get_current_buf() == original and #vim.api.nvim_list_wins() == 1, "modified diff restore lost original source")
enter_status()
vim.cmd("close")
assert(vim.api.nvim_get_current_buf() == original and (vim.b[original].pena_buffer_holds or 0) == 0,
	"closing status directly failed to release session")
print("PASS: unsaved diff edits preserved; direct status close restores original and releases holds")
status.open()
status.open()
assert(vim.wait(5000, function() return vim.bo.filetype == "pena_git_status" end), "repeated status open failed")
vim.wait(100)
assert(#vim.api.nvim_list_wins() == 2 and vim.b[original].pena_buffer_holds == 1, "repeated open leaked a status session")
press("q")
assert((vim.b[original].pena_buffer_holds or 0) == 0, "cancel leaked hold after repeated open")
vim.fn.delete(root, "rf")
print("PASS: rapid status requests retain only the newest session")
vim.cmd("qa!")
