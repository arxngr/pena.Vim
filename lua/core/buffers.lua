local M = {}

function M.close()
	vim.cmd("confirm bdelete")
end

local AGE_SECONDS = 300
local SWEEP_INTERVAL_MS = 60 * 1000
local clock = os.time
local timestamps = {}
local timer
local setup_done = false
local group

local function now()
	return clock()
end

local function touch(buf)
	if vim.api.nvim_buf_is_valid(buf) then
		timestamps[buf] = now()
	end
end

local function is_visible(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			return true
		end
	end
	return false
end

local function is_pinned(buf)
	local ok, pins = pcall(function()
		return vim.g.BufferlinePinnedBuffers
	end)
	if not ok then
		return true
	end
	if pins == nil or pins == "" then
		return false
	end
	if type(pins) ~= "string" then
		return true
	end
	local name_ok, name = pcall(vim.api.nvim_buf_get_name, buf)
	if not name_ok or name == "" then
		return true
	end
	if name:find(",", 1, true) then
		return true
	end
	return ("," .. pins .. ","):find("," .. name .. ",", 1, true) ~= nil
end

local function eligible(buf)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then
		return false
	end
	if vim.bo[buf].buftype ~= "" or vim.bo[buf].modified or vim.api.nvim_buf_get_name(buf) == "" then
		return false
	end
	if is_visible(buf) or is_pinned(buf) then
		return false
	end
	local holds_ok, holds = pcall(function()
		return vim.b[buf].pena_buffer_holds
	end)
	return holds_ok and (holds == nil or (type(holds) == "number" and holds <= 0))
end

function M.sweep(at)
	at = at or now()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if eligible(buf) then
			local last = timestamps[buf]
			if last and at - last >= AGE_SECONDS then
				-- Non-forced deletion refuses modified buffers and avoids changing other windows.
				if pcall(vim.api.nvim_buf_delete, buf, { force = false }) then
					timestamps[buf] = nil
				end
			end
		end
	end
end


function M.setup(opts)
	if setup_done then
		return
	end
	opts = opts or {}
	clock = opts.clock or os.time
	setup_done = true
	group = vim.api.nvim_create_augroup("pena-buffer-cleanup", { clear = true })
	vim.api.nvim_create_autocmd({ "BufAdd", "BufReadPost", "BufEnter", "BufLeave", "TextChanged", "TextChangedI", "BufWritePost" }, {
		group = group,
		callback = function(args)
			touch(args.buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args) timestamps[args.buf] = nil end,
	})
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) then
			touch(buf)
		end
	end
	timer = vim.uv.new_timer()
	timer:start(SWEEP_INTERVAL_MS, SWEEP_INTERVAL_MS, function()
		vim.schedule(function()
			M.sweep()
		end)
	end)
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			if timer then
				timer:stop()
				timer:close()
				timer = nil
			end
		end,
	})
end

return M
