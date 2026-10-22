local M = {}

local active
local reference_cancel
local request_generation = 0

local BATCH_SIZE = 256
local PREVIEW_DELAY_MS = 40
local target_ns = vim.api.nvim_create_namespace("pena-search-target")
local rows_ns = vim.api.nvim_create_namespace("pena-search-rows")

local function define_marker()
	vim.api.nvim_set_hl(0, "PenaSearchWord", { link = "Search" })
	vim.api.nvim_set_hl(0, "PenaSearchRow", {})
end
define_marker()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("pena-search-colors", { clear = true }),
	callback = define_marker,
})

local function hold(buf, delta)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.b[buf].pena_buffer_holds = math.max(0, (vim.b[buf].pena_buffer_holds or 0) + delta)
	end
end

-- Keep syntax definitions scoped to the viewport, not the size of the result set.
local function code_syntax(fallback)
	vim.bo.syntax = ""
	vim.cmd("syntax clear")
	local languages, filetypes, regions = {}, {}, 0
	return function(items, first, last)
		for index = 1, regions do vim.cmd("syntax clear PenaResultRow" .. index) end
		regions = 0
		local runs = {}
		for index = first, last do
			local item = items[index]
			local ft = filetypes[item.bufnr]
			if ft == nil then
				local name = item.bufnr > 0 and vim.api.nvim_buf_get_name(item.bufnr) or ""
				ft = item.bufnr > 0 and vim.bo[item.bufnr].filetype or ""
				ft = ft ~= "" and ft or (vim.filetype.match({ filename = name }) or fallback)
				filetypes[item.bufnr] = ft
			end
			if ft ~= "" and ft:match("^[%w_]+$") then
				if languages[ft] == nil then
					languages[ft] = pcall(vim.cmd, "syntax include @PenaResults" .. ft .. " syntax/" .. ft .. ".vim")
				end
				if languages[ft] then
					local run = runs[#runs]
					if run and run.ft == ft and run.last == index - 1 then
						run.last = index
					else
						runs[#runs + 1] = { ft = ft, first = index, last = index }
					end
				end
			end
		end
		for index, run in ipairs(runs) do
			vim.cmd(("syntax region PenaResultRow%d start=/\\%%>%dl\\%%<%dl^/ end=/$/ keepend transparent contains=@PenaResults%s")
				:format(index, run.first - 1, run.last + 1, run.ft))
		end
		regions = #runs
	end
end

-- Capture the source before the asynchronous request or search prompt completes.
function M.handler(opts)
	opts = opts or {}
	request_generation = request_generation + 1
	local generation = request_generation
	if reference_cancel then
		reference_cancel()
		reference_cancel = nil
	end
	if active then
		active(false, true)
	end
	local source = vim.api.nvim_get_current_win()
	local original = vim.api.nvim_get_current_buf()
	local view = vim.fn.winsaveview()

	return function(list)
		if generation ~= request_generation then return end
		if not vim.api.nvim_win_is_valid(source) or not vim.api.nvim_buf_is_valid(original) then
			return
		end
		if active then
			active(false, true)
		end
		local held = original
		hold(held, 1)
		if opts.word and opts.word ~= "" then
			local pattern = "\\C\\V" .. vim.fn.escape(opts.word, "\\"):gsub("\n", "\\n")
			vim.fn.setreg("/", pattern)
			vim.v.searchforward = 1
			vim.cmd("nohlsearch")
		end
		local function result_text(info)
			local lines = {}
			for index = info.start_idx, info.end_idx do
				local item = list.items[index]
				lines[#lines + 1] = (item.text or ""):gsub("[\r\n]", ""):gsub("^%s+", "")
			end
			return lines
		end
		local total = #list.items
		local title = ("%s — %d results"):format(list.title or "Search", total)
		local items, published = list.items, 0
		local function next_batch()
			local batch = {}
			local last = math.min(total, published + BATCH_SIZE)
			for index = published + 1, last do
				local item = items[index]
				if not item.bufnr or item.bufnr == 0 then
					item.bufnr = item.filename and vim.fn.bufadd(item.filename) or 0
				end
				if item.valid == nil then
					item.valid = item.bufnr > 0 and (item.lnum or 0) > 0 and 1 or 0
				end
				batch[#batch + 1] = item
			end
			published = last
			return batch
		end
		vim.fn.setqflist({}, " ", vim.tbl_extend("force", list, {
			items = next_batch(), title = title, quickfixtextfunc = result_text,
		}))
		vim.cmd("botright copen " .. math.max(1, math.floor(vim.o.lines * 0.35)))
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_get_current_buf()
		local id = vim.fn.getqflist({ id = 0 }).id
		local done, switching, suspended = false, false, false
		local keep_loading = false
		local mappings, initialized = {}, {}
		local marked
		local preview_generation = 0
		local mouse_commit = false
		local group = vim.api.nvim_create_augroup("pena-lsp-results", { clear = true })
		vim.wo[win].number = false
		vim.wo[win].relativenumber = false
		vim.wo[win].cursorline = false
		vim.wo[win].wrap = false
		vim.wo[win].signcolumn = "yes"
		vim.wo[win].winbar = title:gsub("%%", "%%%%")
		vim.opt_local.winhighlight:append({ QuickFixLine = "PenaSearchRow" })

		local function clear_target()
			if marked and vim.api.nvim_buf_is_valid(marked) then
				vim.api.nvim_buf_clear_namespace(marked, target_ns, 0, -1)
			end
			marked = nil
		end

		local function restore()
			clear_target()
			if vim.api.nvim_win_is_valid(source) and vim.api.nvim_buf_is_valid(original) then
				switching = true
				vim.api.nvim_win_call(source, function()
					if vim.api.nvim_get_current_buf() ~= original then
						vim.cmd("hide buffer " .. original)
					end
					vim.fn.winrestview(view)
				end)
				switching = false
			end
		end

		local function selected()
			return items[vim.api.nvim_win_get_cursor(win)[1]]
		end

		local function preview()
			if done or switching or suspended or not vim.api.nvim_win_is_valid(source)
				or not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win then
				return
			end
			local item = selected()
			if not item or item.valid ~= 1 or not item.bufnr or item.bufnr == 0 then
				restore()
				return
			end
			clear_target()
			vim.fn.bufload(item.bufnr)
			switching = true
			local ok, err = pcall(vim.api.nvim_win_call, source, function()
				if vim.api.nvim_get_current_buf() ~= item.bufnr then
					-- :hide preserves modified buffers even when 'hidden' is disabled.
					vim.cmd("hide buffer " .. item.bufnr)
				end
				if not initialized[item.bufnr] then
					if vim.bo.filetype == "" then
						vim.bo.filetype = vim.filetype.match({ buf = item.bufnr }) or ""
					end
					if vim.bo.syntax == "" and vim.bo.filetype ~= "" then
						vim.bo.syntax = vim.bo.filetype
					end
					-- A large preview keeps native syntax without forcing a cold parser.
					if vim.api.nvim_buf_get_offset(item.bufnr, vim.api.nvim_buf_line_count(item.bufnr)) <= 1024 * 1024 then
						pcall(vim.treesitter.start, item.bufnr)
					end
					initialized[item.bufnr] = true
				end
				local line = math.min(math.max(1, item.lnum), vim.api.nvim_buf_line_count(item.bufnr))
				local text = vim.api.nvim_buf_get_lines(item.bufnr, line - 1, line, false)[1] or ""
				local col = math.min(math.max(0, item.col - 1), #text)
				vim.api.nvim_win_set_cursor(source, { line, col })
				vim.cmd("normal! zvzz")
				local word = opts.word and opts.word:match("^[^\n]*")
				local last = word and math.min(#text, col + #word) or col
				vim.api.nvim_buf_set_extmark(item.bufnr, target_ns, line - 1, col, {
					end_col = last, hl_group = word and "PenaSearchWord" or nil, hl_mode = "combine",
					sign_text = ">", sign_hl_group = "Special", priority = 200,
				})
				marked = item.bufnr
			end)
			switching = false
			if not ok then
				vim.notify("Cannot preview search result: " .. tostring(err), vim.log.levels.WARN)
				return
			end
			return true
		end

		local function finish(commit, close)
			if done then
				return
			end
			if commit then
				if not mouse_commit and not preview() then
					return
				end
				vim.fn.setqflist({}, "a", { id = id, idx = vim.api.nvim_win_get_cursor(win)[1] })
			end
			done = true
			keep_loading = commit
			active = nil
			preview_generation = preview_generation + 1
			vim.api.nvim_del_augroup_by_id(group)
			clear_target()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_call(buf, function()
					for key, previous in pairs(mappings) do
						pcall(vim.keymap.del, "n", key, { buffer = buf })
						if previous.buffer == 1 then
							vim.fn.mapset("n", false, previous)
						end
					end
				end)
				vim.api.nvim_buf_clear_namespace(buf, rows_ns, 0, -1)
				vim.bo[buf].syntax = "qf"
			end
			if close and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			vim.fn.setqflist({}, "a", { id = id, quickfixtextfunc = "" })
			if not commit and not suspended then
				restore()
			end
			hold(held, -1)
			if close and vim.api.nvim_win_is_valid(source) then
				vim.api.nvim_set_current_win(source)
			end
		end
		active = finish

		local function queue_preview()
			preview_generation = preview_generation + 1
			local generation = preview_generation
			vim.defer_fn(function()
				if generation == preview_generation then preview() end
			end, PREVIEW_DELAY_MS)
		end

		local draw_visible
		local draw_pending = false
		local function queue_draw()
			if draw_pending or done then return end
			draw_pending = true
			vim.defer_fn(function()
				draw_pending = false
				if draw_visible then draw_visible() end
			end, 1)
		end
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = group, buffer = buf, callback = function() queue_draw(); queue_preview() end,
		})
		vim.api.nvim_create_autocmd("WinScrolled", {
			group = group, pattern = tostring(win), callback = queue_draw,
		})
		vim.api.nvim_create_autocmd("BufLeave", {
			group = group, buffer = buf, callback = function()
				if not switching then
					if mouse_commit then
						vim.schedule(function() finish(true, true) end)
					else
						suspended = true
						restore()
					end
				end
			end,
		})
		vim.api.nvim_create_autocmd("WinEnter", {
			group = group, callback = function()
				if not switching and suspended and vim.api.nvim_get_current_win() == win then
					if vim.api.nvim_win_is_valid(source) then
						local next_buf = vim.api.nvim_win_get_buf(source)
						if held ~= next_buf then
							hold(held, -1)
							held = next_buf
							hold(held, 1)
						end
						original = vim.api.nvim_win_get_buf(source)
						view = vim.api.nvim_win_call(source, vim.fn.winsaveview)
					end
					suspended = false
					queue_draw()
					queue_preview()
				end
			end,
		})
		vim.api.nvim_create_autocmd("WinClosed", {
			group = group, pattern = tostring(win), callback = function() finish(false, false) end,
		})
		vim.api.nvim_create_autocmd("VimResized", {
			group = group, callback = function()
				vim.api.nvim_win_set_height(win, math.max(1, math.floor(vim.o.lines * 0.35)))
				queue_draw()
			end,
		})
		-- Run after generic qf FileType mappings have been installed. Native / and ? stay intact.
		vim.schedule(function()
			if done or not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			local function map(key, callback, desc, expr)
				mappings[key] = vim.fn.maparg(key, "n", false, true)
				vim.keymap.set("n", key, callback, { buffer = buf, nowait = true, desc = desc, expr = expr })
			end
			map("<CR>", function() finish(true, true) end, "Open selected search result")
			map("<Esc>", function() finish(false, true) end, "Cancel search results")
			map("q", function() finish(false, true) end, "Cancel search results")
			map("<2-LeftMouse>", function() finish(true, true) end, "Open selected search result")
			map("<LeftMouse>", function()
				mouse_commit = marked ~= nil and vim.fn.getmousepos().winid == source
				return "<LeftMouse>"
			end, "Select a result or commit the source preview", true)
			local syntax = code_syntax(vim.bo[original].filetype)
			local names = {}
			local word = opts.word and opts.word:match("^[^\n]*")
			local previous_first, previous_last, previous_width, previous_leftcol
			draw_visible = function()
				if done or switching or not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win then return end
				local first = vim.fn.line("w0", win)
				local last = math.min(published, vim.fn.line("w$", win))
				local width = vim.api.nvim_win_get_width(win)
				local leftcol = vim.fn.winsaveview().leftcol
				if first == previous_first and last == previous_last and width == previous_width and leftcol == previous_leftcol then return end
				previous_first, previous_last, previous_width, previous_leftcol = first, last, width, leftcol
				vim.api.nvim_buf_clear_namespace(buf, rows_ns, 0, -1)
				syntax(items, first, last)
				local separator = string.rep("─", math.max(1, width))
				for index = first, last do
					local item = items[index]
					local name = names[item.bufnr]
					if not name then
						name = item.bufnr > 0 and vim.api.nvim_buf_get_name(item.bufnr) or ""
						name = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[Current buffer]"
						names[item.bufnr] = name
					end
					vim.api.nvim_buf_set_extmark(buf, rows_ns, index - 1, 0, {
						virt_lines_above = true,
						virt_lines = {
							{ { name .. ":" .. item.lnum .. ":" .. item.col, "Comment" } },
							{ { separator, "WinSeparator" } },
						},
						sign_text = opts.word and ">" or nil, sign_hl_group = "Special",
					})
					local code = (item.text or ""):gsub("[\r\n]", ""):gsub("^%s+", "")
					if word and word ~= "" then
						local from = math.max(1, leftcol - #word + 1)
						while true do
							local a, b = code:find(word, from, true)
							if not a or a > leftcol + width * 4 + #word then break end
							vim.api.nvim_buf_set_extmark(buf, rows_ns, index - 1, a - 1, {
								end_col = b, hl_group = "PenaSearchWord", hl_mode = "combine", priority = 200,
							})
							from = b + 1
						end
					end
				end
				if first == 1 then vim.fn.winrestview({ topline = 1, topfill = 2 }) end
			end
			local function publish()
				if (done and not keep_loading) or generation ~= request_generation
					or vim.fn.getqflist({ id = 0 }).id ~= id then return end
				local deadline = vim.uv.hrtime() + 4 * 1000000
				repeat
					if published < total then
						vim.fn.setqflist({}, "a", { id = id, items = next_batch() })
					end
				until published >= total or vim.uv.hrtime() >= deadline
				if not done and vim.api.nvim_win_is_valid(win) then
					vim.wo[win].winbar = (published < total and (title .. " (loading " .. published .. "/" .. total .. ")") or title):gsub("%%", "%%%%")
					draw_visible()
				end
				if published < total then vim.defer_fn(publish, 1) end
			end
			draw_visible()
			if published < total then vim.defer_fn(publish, 1) end
		end)
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
	reference_cancel = cancel
	local function alive()
		return not state.cancelled and reference_cancel == cancel
			and vim.api.nvim_win_is_valid(source) and vim.api.nvim_buf_is_valid(original)
	end
	local function fail(err)
		local report = alive()
		cancel()
		if reference_cancel == cancel then reference_cancel = nil end
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
			reference_cancel = nil
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


local function prepare(query, label)
	local options = {}
	local show = M.handler(options)
	if query == nil then
		local aborted = false
		local leave = vim.api.nvim_create_autocmd("CmdlineLeave", {
			callback = function()
				if vim.v.event.cmdtype == "@" then
					aborted = vim.v.event.abort
				end
			end,
		})
		local ok, text = pcall(vim.fn.input, (label or "Search") .. ": ")
		vim.api.nvim_del_autocmd(leave)
		if not ok or aborted then
			return
		end
		query = text
	end
	if query == "" then
		return
	end
	options.word = query
	return query, show
end

local function display(show, title, query, items)
	if #items == 0 then
		vim.notify("No matches for " .. query, vim.log.levels.INFO)
	else
		show({ title = title .. ": " .. query, items = items })
	end
end

local function buffer_matches(buf, query, items)
	vim.fn.bufload(buf)
	local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
	local from, line, line_start = 1, 1, 1
	while true do
		local first, last = text:find(query, from, true)
		if not first then
			return
		end
		while true do
			local newline = text:find("\n", line_start, true)
			if not newline or newline >= first then
				break
			end
			line, line_start = line + 1, newline + 1
		end
		local line_end = text:find("\n", first, true) or (#text + 1)
		local prefix = text:sub(first, last)
		local _, extra_lines = prefix:gsub("\n", "")
		local last_newline = prefix:match(".*()\n")
		items[#items + 1] = {
			bufnr = buf, lnum = line, col = first - line_start + 1,
			end_lnum = line + extra_lines,
			end_col = last_newline and (#prefix - last_newline) or (last - line_start + 1),
			text = text:sub(line_start, line_end - 1),
		}
		from = last + 1
	end
end

function M.current_buffer(query)
	local buf = vim.api.nvim_get_current_buf()
	local show
	query, show = prepare(query)
	if not query then
		return
	end
	local items = {}
	buffer_matches(buf, query, items)
	display(show, "Buffer search", query, items)
end

function M.project(query)
	local root = require("core.project_languages").root(vim.api.nvim_buf_get_name(0))
	local show
	query, show = prepare(query, "Global Search")
	if not query then
		return
	end
	if vim.fn.executable("rg") ~= 1 then
		vim.notify("Project search requires ripgrep (rg)", vim.log.levels.ERROR)
		return
	end
	local args = { "rg", "--json", "--fixed-strings" }
	if query:find("\n", 1, true) then
		args[#args + 1] = "--multiline"
	end
	vim.list_extend(args, { "--", query, "." })
	return vim.system(args, { cwd = root, text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 and result.code ~= 1 then
				vim.notify("Project search failed: " .. (result.stderr or "ripgrep error"), vim.log.levels.ERROR)
				return
			end
			local ok, items = pcall(function()
				local matches = {}
				for line in (result.stdout or ""):gmatch("[^\n]+") do
					local event = vim.json.decode(line)
					if event.type == "match" then
						local data = event.data
						local path = data.path.text or vim.base64.decode(data.path.bytes)
						local text = data.lines.text or vim.base64.decode(data.lines.bytes)
						for _, sub in ipairs(data.submatches) do
							local before = text:sub(1, sub.start)
							local _, extra_lines = before:gsub("\n", "")
							local start = before:match(".*()\n") or 0
							local ending = text:find("\n", sub.start + 1, true) or (#text + 1)
							local through = text:sub(1, sub["end"])
							local _, end_lines = through:gsub("\n", "")
							local end_start = through:match(".*()\n") or 0
							matches[#matches + 1] = {
								filename = vim.fs.joinpath(root, path), lnum = data.line_number + extra_lines,
								col = sub.start - start + 1, end_lnum = data.line_number + end_lines,
								end_col = sub["end"] - end_start, text = text:sub(start + 1, ending - 1),
							}
						end
					end
				end
				return matches
			end)
			if not ok then
				vim.notify("Cannot read ripgrep results: " .. tostring(items), vim.log.levels.ERROR)
				return
			end
			display(show, "Global Search", query, items)
		end)
	end)
end

return M
