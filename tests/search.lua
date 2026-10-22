local function test_navigation()
	vim.opt.rtp:prepend(vim.fn.getcwd())
	vim.cmd("filetype on")
	vim.cmd("syntax enable")
	vim.o.lines = 40
	local results = require("core.search")
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
		local item = vim.fn.getqflist()[line]
		assert(vim.wait(1000, function()
			return vim.api.nvim_win_get_buf(source) == item.bufnr
				and vim.api.nvim_win_get_cursor(source)[1] == item.lnum
		end), "selected result did not finish its asynchronous preview")
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
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_buf(source) == b end), "returning to results did not resume preview")
	move(1)
	assert(vim.api.nvim_win_get_buf(source) == a, "resumed cursor movement did not preview")
	key("<Esc>")
	assert(vim.api.nvim_win_get_buf(source) == original and vim.deep_equal(vim.api.nvim_win_get_cursor(source), { 3, 2 }), "cancel did not restore updated source view")
	print("PASS: leaving suspends; returning resumes; cancel restores latest main-buffer view")
	open()
	vim.api.nvim_feedkeys("/public" .. vim.keycode("<CR>"), "xt", false)
	vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_buf(source) == b end), "native slash did not preview the selected match")
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
end

local function test_text_search()
	vim.opt.rtp:prepend(vim.fn.getcwd())
	require("core.keymaps")
	local search = require("core.search")
	local root = vim.fn.tempname()
	vim.fn.mkdir(root .. "/.git", "p")
	vim.fn.mkdir(root .. "/folder with spaces", "p")
	local query = "--[needle].*"
	local first = root .. "/main.cs"
	local second = root .. "/folder with spaces/other file.cs"
	vim.fn.writefile({ "prefix " .. query .. " suffix", "other line" }, first)
	vim.fn.writefile({ "second " .. query }, second)
	vim.fn.writefile({ "ignored.txt" }, root .. "/.gitignore")
	vim.fn.writefile({ query }, root .. "/ignored.txt")
	vim.cmd("edit " .. vim.fn.fnameescape(first))
	local original = vim.api.nvim_get_current_buf()
	local source = vim.api.nvim_get_current_win()
	vim.api.nvim_buf_set_lines(original, 0, -1, false, { "unsaved " .. query .. " and " .. query, "second line" })
	local function settle()
		assert(vim.wait(3000, function() return vim.bo.buftype == "quickfix" end), "search did not show results")
		vim.wait(20)
	end
	local function cancel()
		vim.fn.maparg("q", "n", false, true).callback()
		assert(vim.api.nvim_get_current_win() == source, "cancel should return to main window")
	end
	search.current_buffer(query)
	settle()
	local items = vim.fn.getqflist()
	assert(#items == 2 and items[1].text:find("unsaved", 1, true), "current search must use unsaved buffer contents")
	assert(items[1].col == 9 and items[1].end_col == 8 + #query and items[2].col == 14 + #query, "buffer match columns incorrect")
	vim.fn.maparg("<CR>", "n", false, true).callback()
	vim.api.nvim_feedkeys("n", "xt", false)
	assert(vim.api.nvim_win_get_cursor(source)[2] == 13 + #query, "n must find the next literal match after committing")
	vim.api.nvim_feedkeys("N", "xt", false)
	assert(vim.api.nvim_win_get_cursor(source)[2] == 8, "N must return to the previous literal match")
	print("PASS: unsaved current-buffer search, repeated literal matches, precise ranges")
	local job = search.project(query)
	assert(job, "project search did not launch ripgrep")
	job:wait()
	settle()
	items = vim.fn.getqflist()
	assert(#items == 2, "project search must honor ignored files and search disk rather than unsaved text")
	local paths = {}
	for _, item in ipairs(items) do
		paths[vim.fs.normalize(vim.api.nvim_buf_get_name(item.bufnr))] = item
		assert(item.col == 8 and item.end_col == 7 + #query, "ripgrep range incorrect")
	end
	assert(paths[vim.fs.normalize(first)] and paths[vim.fs.normalize(second)], "project root or filenames with spaces failed")
	cancel()
	print("PASS: real rg search, ignored files, disk scope, paths with spaces, punctuation and leading-dash query")
	vim.api.nvim_feedkeys("/" .. query .. vim.keycode("<CR>"), "xt", false)
	settle()
	assert(vim.fn.getqflist()[1].text:find("unsaved", 1, true), "slash mapping did not search current buffer")
	-- Inside results the same slash must be native search, not a second result request.
	vim.api.nvim_feedkeys("/unsaved" .. vim.keycode("<CR>"), "xt", false)
	assert(#vim.fn.getqflist() == 2 and vim.bo.buftype == "quickfix", "quickfix slash lost native search behavior")
	cancel()
	vim.api.nvim_feedkeys("?" .. query .. vim.keycode("<CR>"), "xt", false)
	settle()
	assert(not vim.fn.getqflist()[1].text:find("unsaved", 1, true), "question-mark mapping did not search project files")
	cancel()
	print("PASS: actual slash/question-mark key input and native slash inside results")
	vim.api.nvim_feedkeys("/abandoned" .. vim.keycode("<C-c>"), "xt", false)
	assert(vim.api.nvim_get_current_win() == source and vim.bo.buftype ~= "quickfix", "canceled query should not open results")
	vim.fn.delete(root, "rf")
	print("PASS: query cancellation preserves current buffer")
end

local function test_rendering()
	-- Exercise a real Neovim UI grid, not just syntax/extmark metadata.
	local child = vim.fn.jobstart({ vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-n" }, { rpc = true })
	assert(child > 0, "could not start rendering fixture")
	local function lua(code, args) return vim.rpcrequest(child, "nvim_exec_lua", code, args or {}) end
	local ok, err = pcall(function()
		vim.rpcrequest(child, "nvim_ui_attach", 100, 40, { rgb = true })
		lua([[
			vim.opt.rtp:prepend(...)
			vim.o.termguicolors = true
			vim.cmd("syntax enable")
			vim.cmd("colorscheme habamax")
			-- A theme may give QuickFixLine a strong foreground/background.
			vim.api.nvim_set_hl(0, "QuickFixLine", { fg = 0xff0000, bg = 0x0000ff, underline = true })
			local buf = vim.api.nvim_get_current_buf()
			vim.api.nvim_buf_set_name(buf, "render-fixture.cs")
			vim.bo.filetype = "cs"
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "before.AddRange(after);", "before.AddRange(after);" })
			require("core.search").handler({ word = "AddRange" })({ title = "Global Search: AddRange", items = {
				{ bufnr = buf, lnum = 1, col = 8, end_col = 15, text = "before.AddRange(after);" },
				{ bufnr = buf, lnum = 2, col = 8, end_col = 15, text = "before.AddRange(after);" },
			} })
			_G.render_win = vim.api.nvim_get_current_win()
			vim.wait(20)
		]], { vim.fn.getcwd() })
		local function cells()
			vim.rpcrequest(child, "nvim_command", "redraw!")
			return lua([[
				local rows = {}
				for line = 1, 2 do
					local attrs = {}
					for _, col in ipairs({ 1, 7, 8, 15, 16, 22 }) do
						local pos = vim.fn.screenpos(_G.render_win, line, col)
						assert(pos.row > 0 and pos.col > 0, "result code is not visible")
						local char = vim.fn.screenstring(pos.row, pos.col)
						assert(char == ("before.AddRange(after);"):sub(col, col), "screen position does not point at result code: " .. char)
						attrs[#attrs + 1] = vim.fn.screenattr(pos.row, pos.col)
					end
					rows[#rows + 1] = attrs
				end
				return rows
			]])
		end
		local before = cells()
		lua([[
			local function screenline(row)
				local text = {}
				for col = 1, 100 do text[#text + 1] = vim.fn.screenstring(row, col) end
				return table.concat(text)
			end
			local first = vim.fn.screenpos(_G.render_win, 1, 1).row
			assert(screenline(first - 2):find("render-fixture.cs:1:8", 1, true),
				"the first result's path must be visible above its code")
			assert(screenline(first - 1):find("─", 1, true), "path/code separator is not visible")
			local count_visible = false
			for row = 1, first - 3 do
				if screenline(row):find("2 results", 1, true) then count_visible = true end
			end
			assert(count_visible, "total result count must be visible above the list")
		]])
		lua([[vim.api.nvim_set_hl(0, "QuickFixLine", { fg = 0x00ff00, bg = 0xff00ff, bold = true })]])
		assert(vim.deep_equal(before, cells()), "QuickFixLine colors must not override result code")
		lua([[vim.api.nvim_set_hl(0, "Search", { fg = 0xffcc00, bg = 0x222200, bold = true })]])
		local after = cells()
		for line = 1, 2 do
			for _, col in ipairs({ 1, 2, 5, 6 }) do
				assert(vim.deep_equal(before[line][col], after[line][col]), "changing Search colors recolored text outside AddRange")
			end
			for _, col in ipairs({ 3, 4 }) do
				assert(not vim.deep_equal(before[line][col], after[line][col]), "matched text did not adopt the theme's Search colors")
			end
		end
	end)
	vim.rpcnotify(child, "nvim_command", "qa!")
	vim.fn.jobwait({ child }, 2000)
	assert(ok, err)
	print("PASS: actual UI grid colors only matched text; selected rows retain syntax colors; theme Search changes propagate")
end

local function test_async_references()
	vim.cmd("enew!")
	vim.o.hidden = true
	local search = require("core.search")
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	local loaded_path, disk_path = root .. "/loaded.cs", root .. "/large.cs"
	vim.fn.writefile({ "old disk contents", "second" }, loaded_path)
	local lines = {}
	for row = 1, 200000 do lines[row] = "λ😀 UpdateRange();" .. (row < 200000 and "\r" or "") end
	vim.fn.writefile(lines, disk_path, "b")
	lines = nil
	vim.cmd("edit " .. vim.fn.fnameescape(loaded_path))
	local source, original = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(original, 0, -1, false, { "α😀 UpdateRange();", "終x;" })
	vim.api.nvim_win_set_cursor(source, { 1, 7 })
	local clients = {}
	local ok, err = pcall(function()
		for _, encoding in ipairs({ "utf-16", "utf-8", "utf-32" }) do
			local start = ({ ["utf-16"] = 4, ["utf-8"] = 7, ["utf-32"] = 3 })[encoding]
			local locations = { { uri = vim.uri_from_fname(loaded_path), range = {
				start = { line = 0, character = start }, ["end"] = { line = 1, character = encoding == "utf-8" and 5 or 3 },
			}, encoding = encoding } }
			-- Reverse server order to exercise URI and position sorting, including the last disk row.
			for index = 1500, 1, -1 do
				locations[#locations + 1] = { uri = vim.uri_from_fname(disk_path), range = {
					start = { line = 198499 + index, character = start }, ["end"] = { line = 198499 + index, character = start + 11 },
				}, encoding = encoding }
			end
			local config = vim.json.encode({ encoding = encoding, locations = locations })
			local server = root .. "/server-" .. encoding .. ".lua"
			local code = "local config = vim.json.decode(" .. string.format("%q", config) .. ")\n" .. [=[
local function send(id, result)
	local body = vim.json.encode({ jsonrpc = "2.0", id = id, result = result })
	assert(vim.uv.fs_write(1, ("Content-Length: %d\r\n\r\n%s"):format(#body, body), -1))
end
while true do
	local length
	while true do
		local line = io.stdin:read("*l")
		if not line then return end
		if line == "" or line == "\r" then break end
		length = tonumber(line:match("^Content%-Length:%s*(%d+)")) or length
	end
	local message = vim.json.decode(io.stdin:read(assert(length)))
	if message.method == "initialize" then
		send(message.id, { capabilities = { referencesProvider = true, textDocumentSync = 1, positionEncoding = config.encoding } })
	elseif message.method == "textDocument/references" then send(message.id, config.locations)
	elseif message.method == "shutdown" then send(message.id, vim.NIL)
	elseif message.method == "exit" then return end
end
]=]
			vim.fn.writefile(vim.split(code, "\n", { plain = true }), server)
			clients[#clients + 1] = assert(vim.lsp.start({ name = "reference-fixture-" .. encoding,
				cmd = { vim.v.progpath, "--headless", "-u", "NONE", "-n", "-l", server }, root_dir = root,
				capabilities = { general = { positionEncodings = { encoding } } },
			}, { bufnr = original }))
		end
		assert(vim.wait(5000, function()
			for _, id in ipairs(clients) do if not vim.lsp.get_client_by_id(id).initialized then return false end end
			return true
		end), "fixture language servers did not initialize")
		search.references()
		assert(vim.wait(10000, function() return vim.bo.buftype == "quickfix" and #vim.fn.getqflist() == #clients * 1501 end),
			"asynchronous references did not publish all clients' results")
		local items, disk_rows, loaded_count = vim.fn.getqflist(), {}, 0
		for _, item in ipairs(items) do
			local location = item.user_data
			assert(item.col == 8, "LSP character offset was not converted to the UTF-8 byte column")
			if location.uri == vim.uri_from_fname(loaded_path) then
				loaded_count = loaded_count + 1
				assert(item.text == "α😀 UpdateRange();" and item.end_lnum == 2 and item.end_col == 6,
					"unsaved loaded text or multi-line end position was lost")
			else
				assert(item.text == "λ😀 UpdateRange();" and item.end_col == 19, "async disk text or end offset is incorrect")
				local previous = disk_rows[location.encoding] or 0
				assert(item.lnum >= previous, "async disk conversion reordered references")
				disk_rows[location.encoding] = item.lnum
			end
		end
		assert(loaded_count == 3 and disk_rows["utf-8"] == 200000 and disk_rows["utf-16"] == 200000 and disk_rows["utf-32"] == 200000,
			"multiple-client results or final disk row were lost")
		assert(not vim.api.nvim_buf_is_loaded(vim.fn.bufnr(disk_path)), "finding references loaded the large target buffer")
		vim.fn.maparg("q", "n", false, true).callback()
		search.references()
		search.current_buffer("UpdateRange")
		vim.wait(250)
		assert(vim.fn.getqflist({ title = 0 }).title:find("Buffer search", 1, true), "stale references replaced a newer search")
		vim.fn.maparg("q", "n", false, true).callback()
		assert(vim.api.nvim_get_current_buf() == original and vim.bo[original].modified, "cancelling references lost source edits")
	end)
	for _, id in ipairs(clients) do
		local client = vim.lsp.get_client_by_id(id)
		if client then client:stop() end
	end
	assert(vim.wait(2000, function()
		for _, id in ipairs(clients) do
			local client = vim.lsp.get_client_by_id(id)
			if client and not client:is_stopped() then return false end
		end
		return true
	end), "fixture language servers did not stop")
	vim.fn.delete(root, "rf")
	assert(ok, err)
	print("PASS: real LSP multi-client UTF offsets, unsaved text, async large-file reads, stable order and cancellation")
end

local function test_incremental_sessions()
	vim.cmd("enew!")
	vim.o.hidden = true
	local search = require("core.search")
	local function settle_ui()
		local ready = false
		vim.schedule(function() ready = true end)
		assert(vim.wait(1000, function() return ready end), "UI setup did not complete")
	end
	local original, source = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
	local lines, items = {}, {}
	local count = 40000
	for row = 1, count do
		lines[row] = "local UpdateRange = " .. row
		items[row] = { bufnr = original, lnum = row, col = 7, text = lines[row] }
	end
	vim.api.nvim_buf_set_lines(original, 0, -1, false, lines)
	search.handler({ word = "UpdateRange" })({ title = "Large reference list", items = items })
	local win = vim.api.nvim_get_current_win()
	settle_ui()
	-- A newer result session must supersede all pending publication/drawing callbacks.
	local newest = search.handler({ word = "UpdateRange" })
	newest({ title = "Newest results", items = { items[1], items[2] } })
	vim.wait(150)
	assert(#vim.fn.getqflist() == 2 and vim.fn.getqflist({ title = 0 }).title:find("Newest results", 1, true),
		"obsolete list publication corrupted the newer result session")
	vim.fn.maparg("q", "n", false, true).callback()
	search.handler({ word = "UpdateRange" })({ title = "Complete references", items = items })
	assert(vim.wait(5000, function() return vim.api.nvim_buf_line_count(0) == count end), "incremental publication truncated results")
	win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_cursor(win, { count, 0 })
	vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_cursor(source)[1] == count end), "last reference did not preview")
	local ns = vim.api.nvim_get_namespaces()["pena-search-rows"]
	local tail_visible = false
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
		if mark[2] == count - 1 and mark[4].virt_lines then tail_visible = true end
	end
	assert(tail_visible, "scrolling to the final result did not render its path")
	vim.fn.maparg("q", "n", false, true).callback()
	search.handler({ word = "UpdateRange" })({ title = "Early commit", items = items })
	settle_ui()
	assert(vim.api.nvim_buf_line_count(0) < count, "fixture missed the loading-to-commit transition")
	vim.api.nvim_feedkeys(vim.keycode("<CR>"), "mx", false)
	assert(vim.wait(5000, function() return vim.fn.getqflist({ size = 0 }).size == count end),
		"early commit lost unpublished references: " .. #vim.fn.getqflist())
	assert(vim.api.nvim_get_current_win() == source and #vim.api.nvim_list_wins() == 1
		and vim.fn.getqflist({ idx = 0 }).idx == 1, "background publication changed committed focus or position")
	local path = vim.fn.tempname() .. ".lua"
	vim.fn.writefile({ "local UpdateRange = 1" }, path)
	local target = vim.fn.bufadd(path)
	search.handler({ word = "UpdateRange" })({ title = "Cancelled preview", items = {
		{ bufnr = target, lnum = 1, col = 7, text = "local UpdateRange = 1" },
	} })
	settle_ui()
	vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
	vim.api.nvim_feedkeys("q", "mx", false)
	vim.wait(100)
	assert(not vim.api.nvim_buf_is_loaded(target) and vim.api.nvim_get_current_buf() == original,
		"a cancelled pending preview loaded its target or changed the source")
	vim.fn.delete(path)
	print("PASS: latest result session wins, all results remain navigable, viewport rendering and pending preview cancellation")
end

test_navigation()
vim.cmd("enew!")
vim.o.hidden = true
test_text_search()
test_rendering()
test_async_references()
test_incremental_sessions()
vim.cmd("qa!")
