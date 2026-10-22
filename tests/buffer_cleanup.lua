vim.opt.rtp:prepend(vim.fn.getcwd())
local now = 1000
local cleanup = require("core.buffer_cleanup")
cleanup.setup({ clock = function() return now end })
cleanup.setup()

local files = {}
local function filebuf(name)
	local path = vim.fn.tempname() .. name
	files[#files + 1] = path
	vim.fn.writefile({ "clean" }, path)
	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)
	vim.bo[buf].buflisted = true
	return buf
end
local function sweep_at(time)
	now = time
	cleanup.sweep()
end

local clean = filebuf("-expires.txt")
sweep_at(1299)
assert(vim.api.nvim_buf_is_valid(clean), "buffer expired before 300 seconds")
sweep_at(1300)
assert(not vim.api.nvim_buf_is_valid(clean), "hidden clean buffer did not expire at 300 seconds")

local visible = filebuf("-visible.txt")
local modified = filebuf("-modified.txt")
vim.api.nvim_buf_set_lines(modified, 0, -1, false, { "changed" })
local pinned = filebuf("-pinned.txt")
local old_pins = vim.g.BufferlinePinnedBuffers
vim.g.BufferlinePinnedBuffers = vim.api.nvim_buf_get_name(pinned)
local terminal = vim.api.nvim_create_buf(true, false)
vim.api.nvim_open_term(terminal, {})
local special = vim.api.nvim_create_buf(true, true)
local held = filebuf("-held.txt")
vim.b[held].pena_buffer_holds = 1
local current = vim.api.nvim_get_current_buf()
vim.api.nvim_win_set_buf(0, visible)
sweep_at(2000)
for _, buf in ipairs({ visible, modified, pinned, terminal, special, held }) do
	assert(vim.api.nvim_buf_is_valid(buf), "protected buffer was deleted: " .. buf)
end

-- Entering the buffer resets its clock; leaving starts hidden inactivity.
local returning = filebuf("-returning.txt")
sweep_at(2100)
vim.api.nvim_win_set_buf(0, returning)
sweep_at(2200)
vim.api.nvim_win_set_buf(0, current)
sweep_at(2499)
assert(vim.api.nvim_buf_is_valid(returning), "returning buffer expired before 300 seconds hidden")
sweep_at(2500)
assert(not vim.api.nvim_buf_is_valid(returning), "returned hidden buffer did not expire at 300 seconds")

vim.g.BufferlinePinnedBuffers = old_pins
for _, path in ipairs(files) do vim.fn.delete(path) end
print("PASS: deterministic hidden-buffer cleanup and protections")
vim.cmd("qa!")
