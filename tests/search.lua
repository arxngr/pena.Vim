local snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
assert(vim.fn.isdirectory(snacks) == 1, "install snacks.nvim at " .. snacks .. " before running tests/search.lua")
vim.opt.rtp:prepend(snacks)
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.cmd("filetype on")
vim.cmd("syntax enable")
local search = require("core.search")
require("snacks").setup({ picker = { enabled = true, sources = search.sources() } })

local function await_picker(count)
	assert(vim.wait(5000, function()
		local picker = Snacks.picker.get()[1]
		return picker and picker.shown and not picker:is_active() and not picker.list.dirty and picker.list:count() == count
	end), "Snacks result list did not open")
	return assert(Snacks.picker.get()[1])
end
local function key(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "xt", false)
end

local function test_async_references()
	vim.cmd("enew!")
	vim.o.hidden = true
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	local loaded_path, disk_path = root .. "/loaded.cs", root .. "/large.cs"
	vim.fn.writefile({ "old contents", "second" }, loaded_path)
	local disk = {}
	for i = 1, 200000 do disk[i] = "λ😀 UpdateRange();" .. (i < 200000 and "\r" or "") end
	vim.fn.writefile(disk, disk_path, "b")
	local sourcebuf = vim.fn.bufadd(loaded_path)
	vim.fn.bufload(sourcebuf)
	vim.api.nvim_buf_set_lines(sourcebuf, 0, -1, false, { "α😀 UpdateRange();", "終x;" })
	vim.api.nvim_set_current_buf(sourcebuf)
	local definitions = {}
	for index = 1, 2 do
		local path = root .. "/definition-" .. index .. ".cs"
		vim.fn.writefile({ "λ😀 UpdateRange();" }, path)
		definitions[index] = { uri = vim.uri_from_fname(path), range = {
			start = { line = 0, character = 4 }, ["end"] = { line = 0, character = 15 },
		} }
	end
	local clients = {}
	local ok, err = pcall(function()
		for _, encoding in ipairs({ "utf-16", "utf-8", "utf-32" }) do
			local start = ({ ["utf-16"] = 4, ["utf-8"] = 7, ["utf-32"] = 3 })[encoding]
			local locations = { { uri = vim.uri_from_fname(loaded_path), range = {
				start = { line = 0, character = start }, ["end"] = { line = 1, character = encoding == "utf-8" and 5 or 3 },
			} } }
			for index = 1500, 1, -1 do locations[#locations + 1] = { uri = vim.uri_from_fname(disk_path), range = {
				start = { line = 198499 + index, character = start }, ["end"] = { line = 198499 + index, character = start + 11 },
			} } end
			local config = vim.json.encode({ encoding = encoding, locations = locations,
				definitions = encoding == "utf-16" and definitions or nil })
			local server = root .. "/server-" .. encoding .. ".lua"
			local code = "local config = vim.json.decode(" .. string.format("%q", config) .. ")\n" .. [=[
local function send(id, result)
 local body = vim.json.encode({jsonrpc="2.0",id=id,result=result})
 assert(vim.uv.fs_write(1,("Content-Length: %d\r\n\r\n%s"):format(#body,body),-1))
end
while true do
 local length
 while true do local line=io.stdin:read("*l"); if not line then return end; if line=="" or line=="\r" then break end; length=tonumber(line:match("^Content%-Length:%s*(%d+)")) or length end
 local message=vim.json.decode(io.stdin:read(assert(length)))
 if message.method=="initialize" then send(message.id,{capabilities={referencesProvider=true,definitionProvider=config.definitions~=nil,positionEncoding=config.encoding}})
 elseif message.method=="textDocument/references" then send(message.id,config.locations)
 elseif message.method=="textDocument/definition" then send(message.id,message.params.position.line==0 and config.definitions or {config.definitions[1]})
 elseif message.method=="shutdown" then send(message.id,vim.NIL)
 elseif message.method=="exit" then return end
end
]=]
			vim.fn.writefile(vim.split(code, "\n", { plain = true }), server)
			clients[#clients + 1] = assert(vim.lsp.start({ name = "search-reference-" .. encoding,
				cmd = { vim.v.progpath, "--headless", "-u", "NONE", "-n", "-l", server },
				root_dir = root, capabilities = { general = { positionEncodings = { encoding } } },
			}, { bufnr = sourcebuf }))
		end
		assert(vim.wait(5000, function()
			for _, id in ipairs(clients) do if not vim.lsp.get_client_by_id(id).initialized then return false end end
			return true
		end), "fixture LSP servers did not initialize")
		search.references()
		assert(vim.wait(15000, function()
			local picker = Snacks.picker.get()[1]
			return picker and not picker:is_active() and picker.list:count() == #clients * 1501
		end), "async references did not produce every result")
		local picker = assert(Snacks.picker.get()[1])
		local loaded, disk_last, disk_buf = 0, 0, vim.fn.bufnr(disk_path)
		for _, item in ipairs(picker:items()) do
			assert(item.user_data and item.pos, "LSP location metadata was not preserved")
			assert(item.pos[2] == 7, "LSP position encoding was not converted to UTF-8 byte column")
			local item_path = vim.fs.normalize(item.buf and vim.api.nvim_buf_get_name(item.buf) or item.file)
			if item_path == vim.fs.normalize(loaded_path) then
				loaded = loaded + 1
				assert(item.line == "α😀 UpdateRange();" and item.end_pos[1] == 2, "unsaved source text or multi-line range was lost")
			elseif item_path == vim.fs.normalize(disk_path) then
				assert(item.line == "λ😀 UpdateRange();", "async disk text/CRLF normalization failed")
				disk_last = math.max(disk_last, item.pos[1])
			end
		end
		assert(loaded == 3 and disk_last == 200000, "multi-client locations or final disk row were lost")
		assert(not vim.api.nvim_buf_is_loaded(disk_buf), "reference conversion loaded the large target buffer")
		key("q")
		assert(vim.api.nvim_get_current_buf() == sourcebuf and vim.bo[sourcebuf].modified, "cancelling references lost unsaved source")
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		Snacks.picker.lsp_definitions()
		picker = await_picker(2)
		key("j")
		assert(vim.wait(1000, function()
			return vim.fs.normalize(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(picker.main)))
				== vim.fs.normalize(vim.uri_to_fname(definitions[2].uri))
		end), "multiple definitions did not share source preview behavior")
		key("q")
		assert(vim.api.nvim_get_current_buf() == sourcebuf, "definition cancellation did not restore source")
		vim.api.nvim_win_set_cursor(0, { 2, 0 })
		Snacks.picker.lsp_definitions()
		assert(vim.wait(5000, function()
			return #Snacks.picker.get() == 0
				and vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == vim.fs.normalize(vim.uri_to_fname(definitions[1].uri))
		end), "single definition did not retain direct jump behavior")
		assert(vim.bo.buflisted and vim.api.nvim_win_get_cursor(0)[2] == 7, "direct definition lost Unicode column or session listing")
		vim.cmd("hide buffer " .. sourcebuf)
		search.references()
		search.lines({ search = "UpdateRange" })
		picker = await_picker(1)
		assert(picker:current().buf == sourcebuf, "new buffer search was replaced by stale references")
		key("q")
	end)
	for _, id in ipairs(clients) do local client = vim.lsp.get_client_by_id(id); if client then client:stop() end end
	assert(vim.wait(2000, function()
		for _, id in ipairs(clients) do local client = vim.lsp.get_client_by_id(id); if client and not client:is_stopped() then return false end end
		return true
	end), "fixture language servers did not stop")
	vim.fn.delete(root, "rf")
	assert(ok, err)
end

local function test_results()
	vim.cmd("enew!")
	vim.o.hidden = true
	local source, original = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(original, 0, -1, false, { "unsaved source", "second" })
	vim.api.nvim_win_set_cursor(source, { 2, 3 })
	local path = vim.fn.tempname() .. ".lua"
	vim.fn.writefile({ "local UpdateRange = true", "local other = UpdateRange" }, path)
	local target = vim.fn.bufadd(path)
	vim.fn.bufload(target)
	vim.api.nvim_buf_set_lines(target, 0, -1, false, { "local UpdateRange = true", "local other = UpdateRange" })
	local original_cursor = { 2, 3 }
	local function open()
		search.handler({ word = "UpdateRange" })({ title = "References", items = {
			{ bufnr = target, lnum = 1, col = 7, text = "local UpdateRange = true" },
			{ bufnr = target, lnum = 2, col = 14, text = "local other = UpdateRange" },
		} })
		return await_picker(2)
	end
	local stale = search.handler({ word = "UpdateRange" })
	local picker = open()
	stale({ title = "Stale results", items = { { bufnr = target, lnum = 1, col = 7, text = "wrong" } } })
	assert(picker.list:count() == 2, "stale result session replaced the latest list")
	key("q")
	picker = open()
	assert(not picker.layout.root:is_floating()
		and vim.api.nvim_win_get_position(picker.list.win.win)[1] > 0, "results must use a bottom split, not a float")
	assert(picker.list:count() == 2, "result list lost items")
	local result_buf = picker.list.win.buf
	local shown = table.concat(vim.api.nvim_buf_get_lines(result_buf, 0, -1, false), "\n")
	local headers = {}
	for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(result_buf, -1, 0, -1, { details = true })) do
		for _, line in ipairs(mark[4].virt_lines or {}) do
			for _, chunk in ipairs(line) do headers[#headers + 1] = chunk[1] end
		end
	end
	local metadata = table.concat(headers, "\n")
	assert(metadata:find(".lua:1:7", 1, true) and metadata:find(".lua:2:14", 1, true)
		and not shown:find(".lua:", 1, true), "path headers must be visible but excluded from code search")
	assert(shown:find("UpdateRange", 1, true), "result code must remain visible")
	key("j")
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_buf(source) == target and vim.api.nvim_win_get_cursor(source)[1] == 2 end), "j did not preview in source window")
	assert(vim.api.nvim_get_current_win() == picker.list.win.win, "preview stole result focus")
	key("q")
	assert(vim.api.nvim_win_get_buf(source) == original and vim.deep_equal(vim.api.nvim_win_get_cursor(source), original_cursor), "cancel did not restore source buffer and cursor")
	assert(vim.bo[original].modified, "cancel discarded unsaved source edits")
	picker = open()
	key("j")
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_buf(source) == target end), "preview did not settle")
	vim.api.nvim_set_current_win(source)
	assert(vim.api.nvim_win_get_buf(source) == original, "leaving results did not restore source")
	vim.api.nvim_win_set_cursor(source, { 1, 2 })
	vim.api.nvim_set_current_win(picker.list.win.win)
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_buf(source) == target end), "returning did not resume preview")
	key("q")
	assert(vim.api.nvim_win_get_buf(source) == original and vim.deep_equal(vim.api.nvim_win_get_cursor(source), { 1, 2 }),
		"cancel after resuming lost the latest source view")
	vim.api.nvim_win_set_cursor(source, original_cursor)

	picker = open()
	key("/other<CR>")
	assert(picker.list.cursor == 2, "forward search did not navigate matching code")
	key("?UpdateRange<CR>")
	assert(picker.list.cursor == 1, "backward search did not navigate matching code")
	assert(picker.list:count() == 2, "question-mark search filtered results")
	key("N")
	assert(picker.list:count() == 2, "reverse repeat filtered results")
	key("n")
	assert(picker.list:count() == 2, "forward repeat filtered results")
	key("<CR>")
	assert(vim.api.nvim_win_get_buf(source) == target, "Enter did not commit the current result")
	assert(vim.bo[target].buflisted, "committed source is not session-listed")
	local long_path = vim.fn.tempname() .. ".lua"
	local prefix = string.rep("α", 5000) .. " "
	local text = prefix .. "UpdateRange();"
	vim.fn.writefile({ text }, long_path)
	local long_buf = vim.fn.bufadd(long_path)
	search.handler({ word = "UpdateRange" })({ title = "Long reference", items = {
		{ bufnr = long_buf, lnum = 1, col = #prefix + 1, text = text },
	} })
	picker = await_picker(1)
	local code = vim.api.nvim_buf_get_lines(picker.list.win.buf, 0, 1, false)[1]
	assert(code:find("UpdateRange", 1, true) and #code < #prefix
		and not code:gsub("α", ""):gsub("…", ""):find("[\128-\255]"), "reference excerpt hid its match or split UTF-8")
	assert(picker:current().line == text and picker:current().pos[2] == #prefix, "excerpt changed source metadata")
	key("<CR>")
	assert(vim.api.nvim_get_current_buf() == long_buf and vim.bo[long_buf].buflisted
		and vim.api.nvim_win_get_cursor(source)[2] == #prefix, "excerpt commit lost source offset or session listing")
	vim.fn.delete(long_path)
	vim.fn.delete(path)
end

local function test_offscreen_navigation()
	vim.cmd("enew!")
	vim.o.hidden = true
	local source, original = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	local rows, items = {}, {}
	for i = 1, 300 do
		rows[i] = ("local Match = %d"):format(i)
		items[i] = { bufnr = original, lnum = i, col = 7, text = rows[i] }
	end
	vim.api.nvim_buf_set_lines(original, 0, -1, false, rows)
	search.handler({ word = "Match" })({ title = "Large result fixture", items = items })
	local picker = await_picker(300)
	assert(picker.list:count() == 300, "large result list was truncated")
	key("/Match = 300<CR>")
	assert(vim.wait(1000, function() return picker.list.cursor == 300 end), "slash could not reach the final offscreen result")
	assert(picker.list:count() == 300, "slash changed result count")
	key("/Match = 29[89]<CR>")
	assert(picker.list.cursor == 298, "result search failed to wrap around")
	key("n")
	assert(picker.list.cursor == 299, "n did not repeat forward search")
	key("N")
	assert(picker.list.cursor == 298, "N did not repeat backward search")
	key("?Match = 29[89]<CR>")
	assert(picker.list.cursor == 299, "backward search failed to wrap around")
	key("n")
	assert(picker.list.cursor == 298, "n did not preserve backward search direction")
	key("N")
	assert(picker.list.cursor == 299 and picker.list:count() == 300, "N changed search direction or filtered results")
	assert(vim.wait(1000, function() return vim.api.nvim_win_get_cursor(source)[1] == 299 end),
		"offscreen result did not preview at its source position")
	key("q")
	assert(vim.api.nvim_get_current_buf() == original, "cancel did not restore source after offscreen navigation")
end

local function test_snacks_grep()
	local root = vim.fn.tempname()
	vim.fn.mkdir(root .. "/.git", "p")
	local path = root .. "/source file.lua"
	vim.fn.writefile({ "local PenaSnacksSearchUnique = true" }, path)
	vim.fn.writefile({ "PenaSnacksSearchUnique" }, root .. "/ignored.txt")
	vim.fn.writefile({ "ignored.txt" }, root .. "/.gitignore")
	search.grep({ search = "PenaSnacksSearchUnique", cwd = root })
	local picker = await_picker(1)
	local items = picker:items()
	assert(#items == 1 and items[1].text:find("PenaSnacksSearchUnique", 1, true),
		"project search must use Snacks' real grep finder")
	assert(items[1].file and vim.fs.normalize(vim.fs.joinpath(items[1].cwd, items[1].file)) == vim.fs.normalize(path),
		"Snacks grep result lost source path")
	key("q")
	local obsolete = search.grep({ search = "PenaSnacksSearchUnique", cwd = root })
	search.handler({ word = "replacement" })({ title = "Replacement", items = {
		{ bufnr = vim.api.nvim_get_current_buf(), lnum = 1, col = 1, text = "replacement" },
	} })
	local latest = await_picker(1)
	assert(obsolete.closed and #Snacks.picker.get() == 1 and Snacks.picker.get()[1] == latest,
		"superseded unshown grep stole the replacement result session")
	key("q")
	vim.fn.delete(root, "rf")
end

local function test_buffer_queries()
	vim.cmd("enew!")
	local original = vim.api.nvim_get_current_buf()
	local rows = {}
	for i = 1, 5000 do rows[i] = "unchanged " .. i end
	rows[5000] = "α😀 unsaved_boundary"
	vim.api.nvim_buf_set_lines(original, 0, -1, false, rows)
	search.lines({ search = "unsaved_boundary" })
	local picker = await_picker(1)
	assert(picker:current().buf == original and picker:current().pos[1] == 5000
		and picker:current().pos[2] == 7 and picker:current().line == rows[5000],
		"chunked buffer search lost unsaved Unicode text or the final row")
	key("q")
	search.lines({ search = "not_present_anywhere" })
	picker = await_picker(0)
	local header = vim.api.nvim_eval_statusline(vim.wo[picker.list.win.win].winbar, { winid = picker.list.win.win, use_winbar = true }).str
	assert(header:find("0 results", 1, true), "empty result list did not expose its result count")
	key("q")
	assert(vim.api.nvim_get_current_buf() == original and vim.bo[original].modified, "empty result cancellation lost source edits")
end

local function test_ui_grid()
	local child = vim.fn.jobstart({ vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-n" }, { rpc = true })
	assert(child > 0, "could not start embedded UI fixture")
	local function lua(code, args) return vim.rpcrequest(child, "nvim_exec_lua", code, args or {}) end
	local ok, err = pcall(function()
		vim.rpcrequest(child, "nvim_ui_attach", 100, 40, { rgb = true })
		lua([[
			vim.opt.rtp:prepend(...)
			vim.opt.rtp:prepend(vim.fn.getcwd())
			vim.cmd("filetype on")
			vim.cmd("syntax enable")
			vim.cmd("colorscheme habamax")
			vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { fg = 0xff0000, bg = 0x0000ff })
			vim.api.nvim_set_hl(0, "Search", { fg = 0x000000, bg = 0xffff00 })
			local search = require("core.search")
			require("snacks").setup({ picker = { enabled = true, sources = search.sources() } })
			local buf = vim.api.nvim_get_current_buf()
			vim.api.nvim_buf_set_name(buf, "screen-fixture.lua")
			vim.bo[buf].filetype = "lua"
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local Match = 1" })
			search.handler({ word = "Match" })({ title = "Screen results", items = {
				{ bufnr = buf, lnum = 1, col = 7, text = "local Match = 1" },
			} })
			vim.wait(30)
		]], { snacks })
		vim.rpcrequest(child, "nvim_command", "redraw!")
		assert(lua([[
			local found, header, separator, exact = false, false, false, false
			local code_row, code_col
			for row = 1, vim.o.lines do
				local text = {}
				for col = 1, vim.o.columns do text[#text + 1] = vim.fn.screenstring(row, col) end
				local line = table.concat(text)
				found = found or line:find("local Match = 1", 1, true) ~= nil
				header = header or line:find("screen-fixture.lua:1:7", 1, true) ~= nil
				separator = separator or line:find("─", 1, true) ~= nil
				local start = line:find("local Match = 1", 1, true)
				if start then code_row, code_col = row, start end
			end
			if code_row then
				local match = vim.fn.screenattr(code_row, code_col + 6)
				exact = match == vim.fn.screenattr(code_row, code_col + 10)
					and match ~= vim.fn.screenattr(code_row, code_col + 5)
					and match ~= vim.fn.screenattr(code_row, code_col + 11)
					and vim.fn.screenattr(code_row, code_col) ~= vim.fn.screenattr(code_row, code_col + 5)
			end
			return found and header and separator and exact
		]]), "embedded Snacks grid did not show separated code with exact-word highlighting")
	end)
	vim.rpcnotify(child, "nvim_command", "qa!")
	vim.fn.jobwait({ child }, 2000)
	assert(ok, err)
end

test_async_references()
test_results()
test_offscreen_navigation()
test_snacks_grep()
	test_buffer_queries()
test_ui_grid()
vim.cmd("qa!")
