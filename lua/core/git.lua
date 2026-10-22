local M = {}
local status_active
local diff_active

local function hold(buf, delta)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.b[buf].pena_buffer_holds = math.max(0, (vim.b[buf].pena_buffer_holds or 0) + delta)
	end
end

local function git(root, args)
	return vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait()
end

local function entries(output)
	local records = vim.split(output, "\0", { plain = true, trimempty = true })
	local groups = { Staged = {}, Unstaged = {}, Untracked = {}, Conflicts = {} }
	local index = 1
	while index <= #records do
		local record = records[index]
		local x, y, path = record:sub(1, 1), record:sub(2, 2), record:sub(4)
		local old = path
		if x == "R" or x == "C" or y == "R" or y == "C" then
			index = index + 1
			old = records[index]
		end
		local function add(group, code)
			local staged = group == "Staged"
			local conflict = group == "Conflicts"
			groups[group][#groups[group] + 1] = {
				path = path, old = old, code = code, group = group,
				deleted = code == "D" or (x == "D" and y == "D"),
				base_empty = group == "Untracked" or (staged and x == "A") or (conflict and x == "A" and y == "A"),
				base = (staged or conflict) and ("HEAD:" .. old) or (":0:" .. ((y == "R" or y == "C") and old or path)),
				index = staged,
			}
		end
		if x == "?" then
			add("Untracked", "?")
		elseif x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
			add("Conflicts", "U")
		else
			if x ~= " " then add("Staged", x) end
			if y ~= " " then add("Unstaged", y) end
		end
		index = index + 1
	end
	return groups
end

function M.status()
	if status_active then status_active() end
	local source = vim.api.nvim_get_current_win()
	local original = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(original)
	local cwd = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
	local root_result = git(cwd, { "rev-parse", "--show-toplevel" })
	if root_result.code ~= 0 then
		vim.notify("Git status: " .. (root_result.stderr or "not a repository"), vim.log.levels.ERROR)
		return
	end
	local root = vim.trim(root_result.stdout)
	local view = vim.fn.winsaveview()
	local layout = vim.fn.winrestcmd()
	local prior, created, mappings = {}, {}, {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do prior[buf] = true end
	local options = {}
	for _, key in ipairs({ "diff", "foldmethod", "foldenable", "scrollbind", "cursorbind", "wrap" }) do
		options[key] = vim.wo[source][key]
	end
	hold(original, 1)
	local canceled = false
	status_active = function()
		if not canceled then
			canceled = true
			hold(original, -1)
		end
	end
	return vim.system({ "git", "-C", root, "status", "--porcelain=v1", "-z", "--untracked-files=normal" }, { text = true }, function(result)
		vim.schedule(function()
			if canceled then return end
			if not vim.api.nvim_win_is_valid(source) or result.code ~= 0 then
				hold(original, -1)
				status_active = nil
				if result.code ~= 0 then vim.notify("Git status: " .. result.stderr, vim.log.levels.ERROR) end
				return
			end
			local groups = entries(result.stdout)
			local lines, rows = { "Git status — " .. root, "" }, {}
			for _, group in ipairs({ "Staged", "Unstaged", "Untracked", "Conflicts" }) do
				if #groups[group] > 0 then
					lines[#lines + 1] = group
					for _, entry in ipairs(groups[group]) do
						lines[#lines + 1] = "  [" .. entry.code .. "] " .. entry.path:gsub("\n", "\\n"):gsub("\r", "\\r")
						rows[#lines] = entry
					end
					lines[#lines + 1] = ""
				end
			end
			if #lines == 2 then
				hold(original, -1)
				status_active = nil
				vim.notify("Working tree clean", vim.log.levels.INFO)
				return
			end
			vim.cmd("botright new")
			local status_win, status = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
			vim.bo[status].buftype, vim.bo[status].bufhidden, vim.bo[status].buflisted = "nofile", "wipe", false
			vim.api.nvim_buf_set_name(status, "git-status://" .. root)
			vim.api.nvim_buf_set_lines(status, 0, -1, false, lines)
			vim.bo[status].modifiable = false
			vim.bo[status].filetype = "pena_git_status"
			vim.api.nvim_win_set_height(status_win, math.max(1, math.floor(vim.o.lines * 0.35)))
			vim.wo[status_win].cursorline = true
			local group = vim.api.nvim_create_augroup("pena-git-status", { clear = true })
			local mouse_diff = false
			local initialized = {}
			local phase, switching, suspended, left = "status", false, false, nil

			local function scratch(label, data, path)
				local buf = vim.api.nvim_create_buf(false, true)
				created[buf] = true
				vim.api.nvim_buf_set_name(buf, "git-diff://" .. buf .. "/" .. label .. "/" .. path)
				local text = vim.split(data:gsub("\r\n", "\n"), "\n", { plain = true })
				if #text > 1 and text[#text] == "" then table.remove(text) end
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
				vim.bo[buf].filetype = vim.filetype.match({ filename = path }) or ""
				vim.bo[buf].modifiable, vim.bo[buf].readonly = false, true
				return buf
			end
			local function revision(spec, path)
				local res = git(root, { "show", spec })
				if res.code ~= 0 then error("Cannot read Git revision: " .. res.stderr) end
				return scratch(spec, res.stdout, path)
			end
			local function right_buffer(entry)
				if entry.buf and vim.api.nvim_buf_is_valid(entry.buf) then return entry.buf end
				if entry.deleted then
					entry.buf = scratch("deleted", "", entry.path)
				elseif entry.index then
					entry.buf = revision(":0:" .. entry.path, entry.path)
				else
					entry.buf = vim.fn.bufadd(vim.fs.joinpath(root, entry.path))
					if not prior[entry.buf] then created[entry.buf] = true end
					vim.fn.bufload(entry.buf)
				end
				return entry.buf
			end
			local function restore()
				if vim.api.nvim_win_is_valid(source) and vim.api.nvim_buf_is_valid(original) then
					switching = true
					vim.api.nvim_win_call(source, function()
						vim.cmd("hide buffer " .. original)
						vim.fn.winrestview(view)
					end)
					switching = false
				end
			end
			local function selected()
				return rows[vim.api.nvim_win_get_cursor(status_win)[1]]
			end
			local function preview()
				if switching or suspended or phase ~= "status" or not vim.api.nvim_win_is_valid(source) then return end
				local entry = selected()
				if not entry then restore(); return end
				switching = true
				local ok, err = pcall(function()
					local buf = right_buffer(entry)
					vim.api.nvim_win_call(source, function()
						vim.cmd("hide buffer " .. buf)
						if not initialized[buf] then
							if vim.bo.filetype == "" then vim.bo.filetype = vim.filetype.match({ buf = buf }) or "" end
							if vim.bo.syntax == "" then vim.bo.syntax = vim.bo.filetype end
							pcall(vim.treesitter.start, buf)
							initialized[buf] = true
						end
					end)
				end)
				switching = false
				if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
			end
			local function finish(closing_status)
				if phase == "closed" then return end
				phase = "closed"
				status_active = nil
				vim.api.nvim_del_augroup_by_id(group)
				for buf, previous in pairs(mappings) do
					if vim.api.nvim_buf_is_valid(buf) then
						pcall(vim.keymap.del, "n", "<C-o>", { buffer = buf })
						if previous.buffer == 1 then
							vim.api.nvim_buf_call(buf, function() vim.fn.mapset("n", false, previous) end)
						end
					end
				end
				for _, win in ipairs({ left or -1, closing_status and -1 or status_win }) do
					if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, false) end
				end
				if vim.api.nvim_win_is_valid(source) then
					vim.api.nvim_win_call(source, function() vim.cmd("diffoff") end)
					for key, value in pairs(options) do vim.wo[source][key] = value end
				end
				if not suspended then restore() end
				hold(original, -1)
				for buf in pairs(created) do
					if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified
						and #vim.fn.win_findbuf(buf) == 0 and (vim.b[buf].pena_buffer_holds or 0) == 0 then
						pcall(vim.api.nvim_buf_delete, buf, { force = false })
					end
				end
				if vim.api.nvim_win_is_valid(source) then
					vim.api.nvim_set_current_win(source)
					vim.cmd(layout)
				end
			end
			status_active = finish
			local function open_diff()
				local entry = selected()
				if not entry or phase ~= "status" then return end
				local ok, rhs, lhs = pcall(function()
					return right_buffer(entry), entry.base_empty and scratch("empty", "", entry.path) or revision(entry.base, entry.old)
				end)
				if not ok then vim.notify(tostring(rhs), vim.log.levels.ERROR); return end
				phase, suspended = "diff", false
				vim.api.nvim_win_close(status_win, false)
				vim.api.nvim_set_current_win(source)
				vim.cmd("hide buffer " .. rhs)
				if vim.bo[rhs].buftype == "" then vim.bo[rhs].buflisted = true end
				vim.cmd("leftabove vsplit")
				left = vim.api.nvim_get_current_win()
				vim.cmd("hide buffer " .. lhs)
				vim.cmd("diffthis")
				vim.api.nvim_win_call(source, function() vim.cmd("diffthis") end)
				for _, buf in ipairs({ lhs, rhs }) do
					vim.api.nvim_buf_call(buf, function()
						mappings[buf] = vim.fn.maparg("<C-o>", "n", false, true)
					end)
					vim.keymap.set("n", "<C-o>", function()
						finish()
					end, { buffer = buf, desc = "Close Git diff and restore original buffer" })
				end
				vim.api.nvim_set_current_win(source)
			end
			vim.api.nvim_create_autocmd("CursorMoved", { group = group, buffer = status, callback = preview })
			vim.api.nvim_create_autocmd("BufLeave", { group = group, buffer = status, callback = function()
				if phase == "status" and not switching then
					if mouse_diff then
						vim.schedule(open_diff)
					else
						suspended = true
						restore()
					end
				end
			end })
			vim.api.nvim_create_autocmd("WinEnter", { group = group, callback = function()
				if phase == "status" and suspended and not switching and vim.api.nvim_get_current_win() == status_win then
					if vim.api.nvim_win_is_valid(source) then
						local next_buf = vim.api.nvim_win_get_buf(source)
						if next_buf ~= original then hold(original, -1); original = next_buf; hold(original, 1) end
						view = vim.api.nvim_win_call(source, vim.fn.winsaveview)
					end
					suspended = false
					preview()
				end
			end })
			vim.api.nvim_create_autocmd("WinClosed", { group = group, pattern = tostring(status_win), callback = function()
				if phase == "status" then finish(true) end
			end })
			vim.keymap.set("n", "q", finish, { buffer = status, desc = "Cancel Git status preview" })
			vim.keymap.set("n", "<Esc>", finish, { buffer = status, desc = "Cancel Git status preview" })
			vim.keymap.set("n", "<CR>", open_diff, { buffer = status, desc = "Open selected Git diff" })
			vim.keymap.set("n", "<2-LeftMouse>", open_diff, { buffer = status, desc = "Open selected Git diff" })
			vim.keymap.set("n", "<LeftMouse>", function()
				local entry = selected()
				mouse_diff = entry ~= nil and entry.buf ~= nil
					and vim.api.nvim_win_is_valid(source) and vim.fn.getmousepos().winid == source
					and vim.api.nvim_win_get_buf(source) == entry.buf
				return "<LeftMouse>"
			end, { buffer = status, expr = true, desc = "Select a Git file or open its source-preview diff" })
		end)
	end)
end

function M.diff()
	if diff_active then diff_active() end
	local source = vim.api.nvim_get_current_win()
	local original = vim.api.nvim_get_current_buf()
	local view, layout = vim.fn.winsaveview(), vim.fn.winrestcmd()
	local windows, buffers, options = {}, {}, {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do windows[win] = true end
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do buffers[buf] = true end
	for _, key in ipairs({ "diff", "foldmethod", "foldenable", "foldlevel", "foldcolumn", "scrollbind", "cursorbind", "wrap" }) do
		options[key] = vim.wo[source][key]
	end
	vim.cmd("Gvdiffsplit")
	local created, mappings = {}, {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if not windows[win] then created[win] = true end
	end
	local done = false
	local function restore()
		if done then return end
		done, diff_active = true, nil
		for buf, previous in pairs(mappings) do
			if vim.api.nvim_buf_is_valid(buf) then
				pcall(vim.keymap.del, "n", "<C-o>", { buffer = buf })
				if previous.buffer == 1 then
					vim.api.nvim_buf_call(buf, function() vim.fn.mapset("n", false, previous) end)
				end
			end
		end
		for win in pairs(created) do
			if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, false) end
		end
		if vim.api.nvim_win_is_valid(source) then
			vim.api.nvim_set_current_win(source)
			vim.cmd("diffoff")
			for key, value in pairs(options) do vim.wo[source][key] = value end
			if vim.api.nvim_buf_is_valid(original) then
				vim.cmd("hide buffer " .. original)
				vim.fn.winrestview(view)
			end
			vim.cmd(layout)
		end
		for buf in pairs(mappings) do
			if not buffers[buf] and vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified
				and #vim.fn.win_findbuf(buf) == 0 then
				vim.api.nvim_buf_delete(buf, { force = false })
			end
		end
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if win == source or created[win] then
			local buf = vim.api.nvim_win_get_buf(win)
			if not mappings[buf] then
				vim.api.nvim_buf_call(buf, function() mappings[buf] = vim.fn.maparg("<C-o>", "n", false, true) end)
				vim.keymap.set("n", "<C-o>", restore, { buffer = buf, desc = "Close Git diff and restore original buffer" })
			end
		end
	end
	diff_active = restore
end

return M
