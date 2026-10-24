local M = {}
local active, pending_cancel
local request_generation = 0
local colors = vim.api.nvim_create_namespace("pena-search-colors")
local target_ns = vim.api.nvim_create_namespace("pena-search-target")

local function define_colors()
	vim.api.nvim_set_hl(0, "PenaSearchWord", { link = "Search" })
	vim.api.nvim_set_hl(0, "PenaSearchPath", { link = "Comment" })
	-- Scope selection styling to code-result windows, not every Snacks picker.
	vim.api.nvim_set_hl(colors, "SnacksPickerListCursorLine", {})
	vim.api.nvim_set_hl(colors, "SnacksPickerMatch", { link = "Search" })
end
define_colors()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("pena-search-colors", { clear = true }),
	callback = define_colors,
})

local function hold(buf, delta)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.b[buf].pena_buffer_holds = math.max(0, (vim.b[buf].pena_buffer_holds or 0) + delta)
	end
end

local function begin()
	request_generation = request_generation + 1
	if pending_cancel then pending_cancel(); pending_cancel = nil end
	if active then
		local previous = active
		for _, picker in ipairs(Snacks.picker.get({ tab = false })) do
			if picker.opts.pena_state == previous then picker:close() end
		end
	end
	return request_generation
end

function M.title()
	local picker = active and active.picker
	if not picker or picker.closed then return "" end
	return ("%s — %d results%s"):format(picker.title, picker.list:count(),
		picker:is_active() and " (loading…)" or ""):gsub("%%", "%%%%")
end

local function query(label)
	local aborted = false
	local leave = vim.api.nvim_create_autocmd("CmdlineLeave", {
		callback = function()
			if vim.v.event.cmdtype == "@" then aborted = vim.v.event.abort end
		end,
	})
	local ok, value = pcall(vim.fn.input, label)
	vim.api.nvim_del_autocmd(leave)
	if ok and not aborted and value ~= "" then return value end
end

local function item_buffer(item)
	local buf = item.buf or item.bufnr
	if buf and buf > 0 and vim.api.nvim_buf_is_valid(buf) then return buf end
	local file = item.file or item.filename
	if file and file ~= "" then
		local path = item.cwd and vim.fs.joinpath(item.cwd, file) or file
		item.buf = vim.fn.bufadd(vim.fs.normalize(path, { expand_env = false }))
		return item.buf
	end
end

local function code_text(item)
	local buf = item.buf or item.bufnr
	local pos = item.pos or { item.lnum or 1, (item.col or 1) - 1 }
	if buf and buf > 0 and vim.api.nvim_buf_is_loaded(buf) then
		return vim.api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1] or ""
	end
	return item.line or item.text or ""
end

local function excerpt(item, word)
	local text = code_text(item):gsub("[\r\n]", "")
	local indent = #(text:match("^%s*") or "")
	local first, last = indent + 1, #text
	if last - indent > 512 then
		local col = item.pos and item.pos[2] + 1 or item.col or first
		first = math.max(first, col - 48)
		last = math.min(last, math.max(first + 511, col + #(word or "") + 160))
		while first < #text and text:byte(first) >= 128 and text:byte(first) < 192 do first = first + 1 end
		while last < #text and text:byte(last + 1) >= 128 and text:byte(last + 1) < 192 do last = last - 1 end
	end
	local prefix = first > indent + 1 and "… " or ""
	return prefix .. text:sub(first, last) .. (last < #text and " …" or ""), first - 1 - #prefix
end

local function native_syntax(picker, item)
	local state, list = picker.opts.pena_state, picker.list
	local file = item.file or item.filename or ""
	local buf = item.buf or item.bufnr
	local ft = item.ft or (buf and buf > 0 and vim.bo[buf].filetype)
	if not ft or ft == "" then ft = vim.filetype.match({ filename = file }) end
	if not ft or not ft:match("^[%w_]+$") then return end
	local row = list:idx2row(item.idx)
	if state.syntax_rows[row] == ft then return end
	vim.api.nvim_buf_call(list.win.buf, function()
		local group = "PenaCode" .. row
		if state.syntax_rows[row] then vim.cmd("syntax clear " .. group) end
		if state.syntax[ft] == nil then
			state.syntax[ft] = #vim.api.nvim_get_runtime_file("syntax/" .. ft .. ".vim", false) > 0
			if state.syntax[ft] then
				vim.b.current_syntax = nil
				vim.cmd("syntax include @Pena_" .. ft .. " syntax/" .. ft .. ".vim")
				vim.b.current_syntax = nil
			end
		end
		if state.syntax[ft] then
			vim.cmd(("syntax region %s start=/\\%%%dl^/ end=/$/ keepend contains=@Pena_%s"):format(group, row, ft))
		end
	end)
	state.syntax_rows[row] = ft
end

local function format_code(item, picker)
	local state = picker.opts.pena_state
	local code, offset = excerpt(item, state.word)
	local name = item.file or item.filename
	local buf = item.buf or item.bufnr
	if not name or name == "" then name = buf and vim.api.nvim_buf_get_name(buf) or "" end
	local pos = item.pos or { item.lnum or 1, (item.col or 1) - 1 }
	local path = name ~= "" and vim.fn.fnamemodify(item.cwd and vim.fs.joinpath(item.cwd, name) or name, ":~:.") or "[Current buffer]"
	local header = { { ("%s:%d:%d"):format(path, pos[1], pos[2] + 1), "PenaSearchPath" } }
	if picker.opts.icons.files.enabled ~= false then
		local icon, hl = Snacks.util.icon(name, "file", { fallback = picker.opts.icons.files })
		table.insert(header, 1, { icon .. " ", hl })
	end
	local width = vim.api.nvim_win_get_width(picker.list.win.win)
	local line = {
		{ code },
		{ col = 0, virt_lines_above = true, virt_lines = {
			header,
			{ { string.rep("─", math.max(1, width)), "WinSeparator" } },
		} },
		{ col = 0, sign_text = ">", sign_hl_group = "Special" },
	}
	native_syntax(picker, item)
	local function mark(a, b)
		a, b = math.max(0, a - offset), math.min(#code, b - offset)
		if a < b then line[#line + 1] = { col = a, end_col = b, hl_group = "PenaSearchWord", priority = 200 } end
	end
	if item.positions then
		local first, last
		for _, byte in ipairs(item.positions) do
			if last and byte ~= last + 1 then mark(first - 1, last); first = nil end
			first, last = first or byte, byte
		end
		if first then mark(first - 1, last) end
	elseif state.word and state.word ~= "" then
		local from = 1
		while true do
			local a, b = code:find(state.word, from, true)
			if not a then break end
			line[#line + 1] = { col = a - 1, end_col = b, hl_group = "PenaSearchWord", priority = 200 }
			from = b + 1
		end
	end
	if not state.top_pending then
		state.top_pending = true
		vim.defer_fn(function()
			state.top_pending = false
			if state.closed or not picker.list.win:valid() or picker.list.top ~= 1 then return end
			vim.api.nvim_win_call(picker.list.win.win, function() vim.fn.winrestview({ topline = 1, topfill = 2 }) end)
		end, 1)
	end
	return line
end

local function restore(state)
	if not vim.api.nvim_win_is_valid(state.source) or not vim.api.nvim_buf_is_valid(state.original) then return end
	state.switching = true
	vim.api.nvim_win_call(state.source, function()
		vim.cmd("keepjumps hide buffer " .. state.original)
		vim.fn.winrestview(state.view)
	end)
	state.switching = false
end

local function clear_target(state)
	if state.marked and vim.api.nvim_buf_is_valid(state.marked) then
		vim.api.nvim_buf_clear_namespace(state.marked, target_ns, 0, -1)
	end
	state.marked = nil
end

local function release_original(state)
	hold(state.original, -1)
	if vim.api.nvim_buf_is_valid(state.original) then
		vim.bo[state.original].bufhidden = state.hidden
		if state.hidden == "wipe" and #vim.fn.win_findbuf(state.original) == 0
			and not vim.bo[state.original].modified and (vim.b[state.original].pena_buffer_holds or 0) == 0 then
			vim.api.nvim_buf_delete(state.original, { force = false })
		end
	end
end

local function preview(state, item, commit)
	clear_target(state)
	if not item or not vim.api.nvim_win_is_valid(state.source) then return end
	local buf = item_buffer(item)
	if not buf then return end
	vim.fn.bufload(buf)
	local pos = item.pos or { item.lnum or 1, (item.col or 1) - 1 }
	local row = math.min(math.max(1, pos[1]), vim.api.nvim_buf_line_count(buf))
	local text = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
	state.switching = true
	vim.api.nvim_win_call(state.source, function()
		vim.cmd("keepjumps hide buffer " .. buf)
		vim.api.nvim_win_set_cursor(state.source, { row, math.min(#text, math.max(0, pos[2])) })
		vim.cmd("normal! zv")
	end)
	state.switching = false
	if commit then
		if vim.bo[buf].buftype == "" then vim.bo[buf].buflisted = true end
	elseif state.word and state.word ~= "" then
		local from = 1
		while true do
			local a, b = text:find(state.word, from, true)
			if not a then break end
			vim.api.nvim_buf_set_extmark(buf, target_ns, row - 1, a - 1, {
				end_col = b, hl_group = "PenaSearchWord", priority = 200,
			})
			from = b + 1
		end
		state.marked = buf
	end
end

local function seek(picker, direction, prompt)
	local state = picker.opts.pena_state
	local pattern = prompt and query(direction == 1 and "/" or "?") or state.pattern
	if not pattern then return end
	local ok, regex = pcall(vim.regex, pattern)
	if not ok then vim.notify(regex, vim.log.levels.ERROR); return end
	state.pattern = pattern
	if prompt then state.direction = direction; vim.fn.setreg("/", pattern); vim.v.searchforward = direction == 1 and 1 or 0 end
	local count, start, scanned = picker.list:count(), picker.list.cursor, 0
	state.seek_serial = state.seek_serial + 1
	local serial = state.seek_serial
	local function step()
		if state.closed or serial ~= state.seek_serial then return end
		local deadline = vim.uv.hrtime() + 2 * 1000000
		while scanned < count do
			scanned = scanned + 1
			local index = (start - 1 + direction * scanned) % count + 1
			local item = picker.list:get(index)
			Snacks.picker.util.resolve(item)
			if regex:match_str(excerpt(item, state.word)) then
				picker.list:move(index, true, true)
				return
			end
			if vim.uv.hrtime() >= deadline then vim.defer_fn(step, 1); return end
		end
		vim.notify("Pattern not found: " .. pattern)
	end
	step()
end

local function configure(opts)
	if opts.pena_state and not opts.pena_state.closed then return opts end
	begin()
	local origin = opts.pena_origin
	local source = origin and origin.source or vim.api.nvim_get_current_win()
	local original = origin and origin.original or vim.api.nvim_win_get_buf(source)
	local state = {
		source = source, original = original, view = origin and origin.view or vim.fn.winsaveview(),
		word = opts.pena_word or (type(opts.search) == "string" and opts.search or nil),
		syntax = {}, syntax_rows = {}, serial = 0, seek_serial = 0, direction = 1,
		hidden = vim.bo[original].bufhidden,
	}
	opts.pena_state = state
	hold(original, 1)
	if state.hidden ~= "" then vim.bo[original].bufhidden = "hide" end
	active = state
	local function close()
		if state.closed then return end
		state.closed = true
		state.serial, state.seek_serial = state.serial + 1, state.seek_serial + 1
		clear_target(state)
		if not state.committed and not state.suspended then restore(state) end
		release_original(state)
		if state.group then vim.api.nvim_del_augroup_by_id(state.group) end
		if active == state then active = nil end
	end
	opts.on_close = close
	opts.actions.confirm = function(picker, item)
		restore(state)
		vim.api.nvim_win_call(state.source, function()
			if opts.jump.jumplist then vim.cmd("normal! m'") end
			if opts.jump.tagstack then
				local from = vim.fn.getpos(".")
				from[1] = state.original
				vim.fn.settagstack(state.source, { items = { { tagname = vim.fn.expand("<cword>"), from = from } } }, "t")
			end
		end)
		preview(state, item, true)
		state.committed = true
		picker:close()
	end
	opts.actions.pena_next = function(picker) seek(picker, state.direction, false) end
	opts.actions.pena_previous = function(picker) seek(picker, -state.direction, false) end
	opts.actions.pena_forward = function(picker) seek(picker, 1, true) end
	opts.actions.pena_backward = function(picker) seek(picker, -1, true) end
	opts.on_change = function(picker, item, force)
		state.picker = picker
		if not item or (state.current == item and not force) then return end
		local previous = state.current
		state.current = item
		-- Do not cold-load a large file merely because it is the first result.
		if not previous and not force then return end
		state.serial = state.serial + 1
		local serial = state.serial
		vim.defer_fn(function()
			if state.closed or state.suspended or serial ~= state.serial
				or vim.api.nvim_get_current_win() ~= picker.list.win.win then return end
			preview(state, item, false)
		end, 40)
		if picker.list.win:valid() and picker.list.top == 1 then
			vim.api.nvim_win_call(picker.list.win.win, function() vim.fn.winrestview({ topline = 1, topfill = 2 }) end)
		end
	end
	opts.on_show = function(picker)
		state.picker = picker
		local win, buf = picker.list.win.win, picker.list.win.buf
		vim.api.nvim_win_set_hl_ns(win, colors)
		vim.wo[win].signcolumn = "yes:1"
		vim.wo[win].wrap, vim.wo[win].scrolloff = false, 0
		-- Snacks counts logical items, while each code item occupies three screen
		-- rows. Keep its viewport capacity in item units so native scrolling never
		-- desynchronizes the selected backing item from its rendered buffer row.
		local function resize()
			if state.closed or not vim.api.nvim_win_is_valid(win) then return end
			picker.list.state.height = math.max(1, math.floor(vim.api.nvim_win_get_height(win) / 3))
			picker.list.dirty = true
			picker.list:render()
		end
		state.group = vim.api.nvim_create_augroup("pena-search-session-" .. picker.id, { clear = true })
		vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, { group = state.group, callback = function() vim.schedule(resize) end })
		vim.api.nvim_create_autocmd("BufLeave", { group = state.group, buffer = buf, callback = function()
			if state.switching or state.closed then return end
			state.suspended = true
			state.serial = state.serial + 1
			clear_target(state)
			restore(state)
		end })
		vim.api.nvim_create_autocmd("BufEnter", { group = state.group, buffer = buf, callback = function()
			if state.switching or state.closed or not state.suspended then return end
			if vim.api.nvim_win_is_valid(state.source) then
				local next_buf = vim.api.nvim_win_get_buf(state.source)
				if next_buf ~= state.original then
					release_original(state)
					state.original, state.hidden = next_buf, vim.bo[next_buf].bufhidden
					hold(next_buf, 1)
					if state.hidden ~= "" then vim.bo[next_buf].bufhidden = "hide" end
				end
				state.view = vim.api.nvim_win_call(state.source, vim.fn.winsaveview)
			end
			state.suspended = false
			opts.on_change(picker, picker:current(), true)
		end })
		picker:focus("list")
		resize()
	end
	return opts
end

local function code_source()
	return {
		config = configure, format = format_code, focus = "list", live = false, main = { current = true },
		supports_live = false, show_empty = true, auto_close = false, sort = { fields = { "idx" } },
		actions = {},
		layout = {
			preview = false, hidden = { "input", "preview" }, cycle = false,
			layout = { box = "vertical", position = "bottom", width = 0, height = 0.35,
				border = "none", { win = "list", border = "none" } },
		},
		win = { list = { wo = { signcolumn = "yes:1", wrap = false, number = false, relativenumber = false,
			winbar = "%{%v:lua.require'core.search'.title()%}" }, keys = {
			["/"] = "pena_forward", ["?"] = "pena_backward",
			["n"] = "pena_next", ["N"] = "pena_previous",
			["q"] = "cancel", ["<Esc>"] = "cancel", ["i"] = false, ["a"] = false,
			-- Keep window navigation global; Snacks otherwise uses these for list movement.
			["<c-j>"] = false, ["<c-k>"] = false,
		} } },
	}
end

function M.sources()
	local sources = {}
	for _, name in ipairs({ "grep", "grep_word", "grep_buffers", "lines", "lsp_declarations", "lsp_definitions",
		"lsp_implementations", "lsp_incoming_calls", "lsp_outgoing_calls", "lsp_references", "lsp_type_definitions",
		"lsp_workspace_symbols", "lsp_symbols" }) do
		sources[name] = code_source()
	end
	return sources
end

function M.grep(opts)
	opts = vim.tbl_extend("force", {}, opts or {})
	local value = opts.search or query("Search project: ")
	if not value or value == "" then return end
	opts.search, opts.pena_word = value, value
	return Snacks.picker.grep(opts)
end

function M.word(opts)
	local selection = Snacks.picker.util.visual()
	local value = selection and selection.text or vim.fn.expand("<cword>")
	if value == "" then return end
	return Snacks.picker.grep_word(vim.tbl_extend("force", opts or {}, {
		search = value, pena_word = value, regex = false,
	}))
end

function M.lines(opts)
	opts = vim.tbl_extend("force", {}, opts or {})
	local value = opts.search or query("Search buffer: ")
	if not value or value == "" then return end
	local buf = vim.api.nvim_get_current_buf()
	opts.pena_word, opts.pattern, opts.search = value, "", ""
	opts.finder = function(_, ctx)
		return function(cb)
			local total = ctx.async:schedule(function() return vim.api.nvim_buf_line_count(buf) end)
			for first = 0, total - 1, 256 do
				local rows = ctx.async:schedule(function()
					return vim.api.nvim_buf_get_lines(buf, first, math.min(first + 256, total), false)
				end)
				for index, text in ipairs(rows) do
					local col = text:find(value, 1, true)
					if col then cb({ buf = buf, text = text, line = text, pos = { first + index, col - 1 } }) end
				end
			end
		end
	end
	return Snacks.picker.lines(opts)
end

function M.workspace_symbols()
	local value = query("Workspace symbols: ")
	if value then vim.lsp.buf.workspace_symbol(value, { on_list = M.handler({ word = value }) }) end
end

function M.handler(opts)
	opts = opts or {}
	local generation = begin()
	local origin = { source = vim.api.nvim_get_current_win(), original = vim.api.nvim_get_current_buf(), view = vim.fn.winsaveview() }
	return function(list)
		if generation ~= request_generation or not vim.api.nvim_win_is_valid(origin.source)
			or not vim.api.nvim_buf_is_valid(origin.original) then return end
		local config = code_source()
		config.title, config.pena_word, config.pena_origin = list.title or "Results", opts.word, origin
		config.finder = function()
			return function(cb)
				for _, item in ipairs(list.items or {}) do
					local text = item.text or ""
					cb({ buf = item.bufnr and item.bufnr > 0 and item.bufnr or nil, file = item.filename,
						pos = { item.lnum or 1, (item.col or 1) - 1 }, text = text,
						line = text, end_pos = item.end_lnum and { item.end_lnum, item.end_col or 0 } or nil,
						user_data = item.user_data })
				end
			end
		end
		return Snacks.picker.pick(config)
	end
end

-- Stable merge sorting yields between bounded pieces of a large server response.
local function sort_references(entries, checkpoint)
	local width, scratch = 1, {}
	local function before(a, b)
		if a.uri ~= b.uri then return a.uri < b.uri end
		local x, y = a.range.start, b.range.start
		return x.line < y.line or (x.line == y.line and x.character <= y.character)
	end
	while width < #entries do
		for first = 1, #entries, width * 2 do
			local middle, last = math.min(first + width, #entries + 1), math.min(first + width * 2 - 1, #entries)
			local a, b = first, middle
			for index = first, last do
				if a < middle and (b > last or before(entries[a], entries[b])) then
					scratch[index], a = entries[a], a + 1
				else
					scratch[index], b = entries[b], b + 1
				end
				checkpoint()
			end
		end
		entries, scratch = scratch, entries
		width = width * 2
	end
	return entries
end

-- File URI reads are asynchronous and retain only the requested rows.
local function reference_lines(uri, needed, last, state, await, checkpoint)
	local buf = vim.uri_to_bufnr(uri)
	local lines = {}
	if vim.api.nvim_buf_is_loaded(buf) or uri:sub(1, 5) ~= "file:" then
		if not vim.api.nvim_buf_is_loaded(buf) then vim.fn.bufload(buf) end
		for row in pairs(needed) do
			lines[row] = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
			checkpoint()
		end
		return buf, lines
	end
	state.fd = await(vim.uv.fs_open, vim.uri_to_fname(uri), "r", 438)
	local offset, row, parts = 0, 0, {}
	while row <= last do
		local data = await(vim.uv.fs_read, state.fd, 64 * 1024, offset)
		if #data == 0 then
			if needed[row] then lines[row] = table.concat(parts):gsub("\r$", "") end
			break
		end
		offset = offset + #data
		local from = 1
		while from <= #data and row <= last do
			local newline = data:find("\n", from, true)
			if needed[row] then parts[#parts + 1] = data:sub(from, newline and newline - 1 or #data) end
			if not newline then break end
			if needed[row] then
				lines[row] = table.concat(parts):gsub("\r$", "")
				parts = {}
			end
			row, from = row + 1, newline + 1
			checkpoint()
		end
	end
	local fd = state.fd
	state.fd = nil
	await(vim.uv.fs_close, fd)
	return buf, lines
end

function M.references()
	local show = M.handler({ word = vim.fn.expand("<cword>") })
	local source, original = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	local state = { cancelled = false }
	local cancel
	local function close_file()
		if state.fd and not state.reading then
			local fd = state.fd
			state.fd = nil
			vim.uv.fs_close(fd, function() end)
		end
	end
	cancel = function()
		if state.cancelled then return end
		state.cancelled = true
		if state.cancel_request then state.cancel_request() end
		close_file()
	end
	pending_cancel = cancel
	local function alive()
		return not state.cancelled and pending_cancel == cancel
			and vim.api.nvim_win_is_valid(source) and vim.api.nvim_buf_is_valid(original)
	end
	local function fail(err)
		local report = alive()
		cancel()
		if pending_cancel == cancel then pending_cancel = nil end
		if report then vim.notify("References: " .. tostring(err), vim.log.levels.ERROR) end
	end
	state.cancel_request = vim.lsp.buf_request_all(original, "textDocument/references", function(client)
		local params = vim.lsp.util.make_position_params(source, client.offset_encoding)
		params.context = { includeDeclaration = true }
		return params
	end, function(results)
		if not alive() then cancel(); return end
		local thread, step
		local operations, slice_start = 0, vim.uv.hrtime()
		local function checkpoint()
			operations = operations + 1
			if operations >= 128 then
				operations = 0
				if vim.uv.hrtime() - slice_start >= 4 * 1000000 then coroutine.yield() end
			end
		end
		local function await(fn, ...)
			local result, failure
			state.reading = true
			local args = { ... }
			args[#args + 1] = function(err, value)
				vim.schedule(function()
					state.reading = false
					if not alive() then
						-- An open can finish after cancellation, before its fd was assigned.
						if fn == vim.uv.fs_open and value then state.fd = value end
						close_file()
						return
					end
					result, failure = value, err
					step()
				end)
			end
			fn(unpack(args))
			coroutine.yield("io")
			if failure then error(failure, 0) end
			return result
		end
		thread = coroutine.create(function()
			local items = {}
			for client_id, response in pairs(results) do
				if response.error or response.err then error(vim.inspect(response.error or response.err), 0) end
				local client = vim.lsp.get_client_by_id(client_id)
				if client then
					local entries = {}
					for _, location in ipairs(response.result or {}) do
						entries[#entries + 1] = { uri = location.uri or location.targetUri,
							range = location.range or location.targetSelectionRange, location = location }
						checkpoint()
					end
					entries = sort_references(entries, checkpoint)
					local first = 1
					while first <= #entries do
						local uri = entries[first].uri
						local after, needed, last = first, {}, 0
						while after <= #entries and entries[after].uri == uri do
							local range = entries[after].range
							needed[range.start.line], needed[range["end"].line] = true, true
							last = math.max(last, range.start.line, range["end"].line)
							after = after + 1
							checkpoint()
						end
						local buf, lines = reference_lines(uri, needed, last, state, await, checkpoint)
						for index = first, after - 1 do
							local entry = entries[index]
							local a, b = entry.range.start, entry.range["end"]
							local text, end_text = lines[a.line] or "", lines[b.line] or ""
							items[#items + 1] = { bufnr = buf, lnum = a.line + 1, end_lnum = b.line + 1,
								col = vim.str_byteindex(text, client.offset_encoding, a.character, false) + 1,
								end_col = vim.str_byteindex(end_text, client.offset_encoding, b.character, false) + 1,
								text = text, user_data = entry.location }
							checkpoint()
						end
						first = after
					end
				end
			end
			pending_cancel = nil
			if #items == 0 then vim.notify("No references found") else show({ title = "References", items = items }) end
		end)
		step = function()
			if not alive() then cancel(); return end
			slice_start = vim.uv.hrtime()
			local ok, waiting = coroutine.resume(thread)
			if not ok then fail(waiting)
			elseif coroutine.status(thread) ~= "dead" and waiting ~= "io" then vim.defer_fn(step, 1) end
		end
		vim.defer_fn(step, 1)
	end)
	return cancel
end

return M
