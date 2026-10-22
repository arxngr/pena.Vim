local M = {}
local active

function M.open()
	if active then active() end
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
		done, active = true, nil
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
	active = restore
end

return M
