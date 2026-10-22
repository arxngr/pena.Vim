vim.opt.rtp:prepend(vim.fn.getcwd())
vim.cmd("filetype on")
vim.cmd("syntax enable")
vim.o.lines = 40
local results = require("core.lsp_results")
local source = vim.api.nvim_get_current_win()
local original = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(original, 0, -1, false, { "original one", "original two", "original three" })
vim.api.nvim_win_set_cursor(source, { 2, 3 })
local a = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(a, 0, -1, false, { "void UpdateRange()", "first target" })
local path = vim.fn.tempname() .. ".cs"
vim.fn.writefile({ "public class Example {", "    public void UpdateRange() {}", "}" }, path)
local b = vim.fn.bufadd(path)
local function open()
	results.handler({ word = "UpdateRange" })({ title = "References", items = {
		{ bufnr = a, lnum = 1, col = 6, end_col = 16, text = "void UpdateRange()\r" },
		{ bufnr = b, lnum = 2, col = 17, end_col = 27, text = "    public void UpdateRange() {}\r" },
	} })
	vim.wait(20)
	return vim.api.nvim_get_current_win()
end
local function key(k)
	vim.fn.maparg(k, "n", false, true).callback()
end
local function move(line)
	vim.api.nvim_win_set_cursor(0, { line, 0 })
	vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
end
local qf = open()
assert(vim.api.nvim_win_get_height(qf) == 14, "expected 35-percent height")
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(lines[2] == "public void UpdateRange() {}", "code should be separate from path and free of CR characters")
local rows = vim.api.nvim_buf_get_extmarks(0, vim.api.nvim_get_namespaces()["pena-search-rows"], 0, -1, { details = true })
local headers = {}
local word_marks = {}
for _, mark in ipairs(rows) do
	if mark[4].virt_lines then
		headers[#headers + 1] = mark
	elseif mark[4].hl_group == "PenaSearchWord" then
		word_marks[#word_marks + 1] = mark
	end
end
rows = headers
assert(#word_marks == 2 and word_marks[2][4].end_col - word_marks[2][3] == #"UpdateRange",
	"the searched word must be marked precisely in code rows")
assert(rows[2][4].virt_lines_above and rows[2][4].virt_lines[1][1][1]:find(vim.fn.fnamemodify(path, ":t"), 1, true), "path should occupy a separate display line")
assert(rows[2][4].virt_lines[2][1][1]:find("─", 1, true), "path and code need a visible separator")
local code_keyword = vim.fn.synIDtrans(vim.fn.synID(2, 1, 1))
assert(code_keyword ~= 0, "result code must use language syntax instead of quickfix filename coloring")
move(2)
assert(vim.api.nvim_win_get_buf(source) == b and vim.api.nvim_win_get_cursor(source)[1] == 2, "second result did not preview")
assert(vim.api.nvim_get_current_win() == qf, "preview stole list focus")
assert(vim.bo[b].filetype == "cs" and vim.bo[b].syntax == "cs", "newly loaded preview must detect syntax")
local syntax = vim.api.nvim_win_call(source, function() return vim.fn.synID(2, 5, 1) end)
assert(syntax ~= 0, "preview keyword has no syntax highlight")
assert(code_keyword == vim.api.nvim_win_call(source, function() return vim.fn.synIDtrans(vim.fn.synID(2, 5, 1)) end),
	"result keywords should use the same theme group as the source buffer")
local ns = vim.api.nvim_get_namespaces()["pena-search-target"]
local target = vim.api.nvim_buf_get_extmarks(b, ns, 0, -1, { details = true })
assert(target[1][4].sign_text:find(">", 1, true) and target[1][4].hl_group == "PenaSearchWord"
	and target[1][4].end_col - target[1][3] == #"UpdateRange", "preview must mark the exact searched word")
move(1)
assert(vim.api.nvim_win_get_buf(source) == a, "moving up did not preview")
assert(#vim.api.nvim_buf_get_extmarks(b, ns, 0, -1, {}) == 0, "old preview marker leaked")
key("q")
assert(vim.api.nvim_win_get_buf(source) == original, "cancel did not restore source")
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(source), { 2, 3 }), "cancel did not restore cursor")
print("PASS: separate code/path rows, CR cleanup, syntax coloring, target sign, up/down preview, cancel")
qf = open()
move(2)
vim.api.nvim_set_current_win(source)
assert(vim.api.nvim_win_get_buf(source) == original, "leaving results did not restore source")
assert(#vim.api.nvim_buf_get_extmarks(b, ns, 0, -1, {}) == 0, "suspended preview retained target sign")
vim.api.nvim_win_set_cursor(source, { 3, 2 })
vim.api.nvim_set_current_win(qf)
assert(vim.api.nvim_win_get_buf(source) == b, "returning to results did not resume preview")
move(1)
assert(vim.api.nvim_win_get_buf(source) == a, "resumed cursor movement did not preview")
key("<Esc>")
assert(vim.api.nvim_win_get_buf(source) == original and vim.deep_equal(vim.api.nvim_win_get_cursor(source), { 3, 2 }), "cancel did not restore updated source view")
print("PASS: leaving suspends; returning resumes; cancel restores latest main-buffer view")
open()
vim.api.nvim_feedkeys("/public" .. vim.keycode("<CR>"), "xt", false)
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
assert(vim.api.nvim_win_get_cursor(0)[1] == 2 and vim.api.nvim_win_get_buf(source) == b, "native slash search should select and preview matching code")
assert(#vim.fn.getqflist() == 2, "native slash must not filter results")
key("<CR>")
assert(vim.api.nvim_get_current_win() == source and vim.api.nvim_win_get_buf(source) == b, "Enter did not commit")
assert(#vim.api.nvim_list_wins() == 1 and vim.fn.getqflist({ idx = 0 }).idx == 2, "committed quickfix position incorrect")
assert(#vim.api.nvim_buf_get_extmarks(b, ns, 0, -1, {}) == 0, "opening a result must clear preview markers")
assert((vim.b[original].pena_buffer_holds or 0) == 0, "committing must release the original buffer hold")
print("PASS: native slash finds code without filtering; Enter commits selection")
vim.api.nvim_win_set_buf(source, original)
open()
move(2)
vim.o.mouse = "a"
local position = vim.api.nvim_win_get_position(source)
vim.api.nvim_input_mouse("left", "press", "", 0, position[1] + 1, position[2] + 18)
vim.api.nvim_input_mouse("left", "release", "", 0, position[1] + 1, position[2] + 18)
vim.api.nvim_feedkeys(vim.keycode("<LeftMouse>"), "mx", false)
assert(vim.wait(1000, function() return #vim.api.nvim_list_wins() == 1 end), "clicking the preview must commit and close the result list")
assert(vim.api.nvim_get_current_buf() == b and #vim.api.nvim_buf_get_extmarks(b, ns, 0, -1, {}) == 0,
	"clicking the preview must commit the buffer and clear its preview markers")
vim.api.nvim_win_set_buf(source, original)
open()
move(2)
vim.cmd("cclose")
assert(vim.api.nvim_win_get_buf(source) == original, "closing result window did not restore source")
open()
move(2)
vim.api.nvim_set_current_win(source)
vim.api.nvim_win_set_cursor(source, { 1, 1 })
vim.cmd("cclose")
local latest = vim.api.nvim_win_get_cursor(source)
assert(latest[1] == 1 and latest[2] == 1, "closing suspended results changed the main-buffer cursor")
vim.o.hidden = false
open()
move(2)
assert(vim.api.nvim_win_get_buf(source) == b, "preview failed with unsaved original and nohidden")
key("q")
assert(vim.bo[original].modified and vim.api.nvim_buf_get_lines(original, 0, 1, false)[1] == "original one", "unsaved edits lost")
vim.fn.delete(path)
print("PASS: close restores source; unsaved edits survive previews with nohidden")
vim.cmd("qa!")
