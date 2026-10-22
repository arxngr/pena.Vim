local M = {}

local function prepare(query, label)
	local options = {}
	local show = require("core.lsp_results").handler(options)
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
