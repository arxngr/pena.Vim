local M = {}

-- Open config
M.open_config = function()
    vim.cmd("edit $MYVIMRC")
end

-- Restore last session
M.restore_last_session = function()
    local session_file = vim.fn.stdpath("data") .. "/session.vim"
    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! source " .. session_file)
        vim.cmd("silent! tabfirst") -- optional: go to the first tab
        print("Session restored.")
    else
        print("No session found.")
    end
end

-- Save session manually
M.save_session = function()
    local session_file = vim.fn.stdpath("data") .. "/session.vim"
    vim.opt.sessionoptions = {
        "buffers",
        "curdir",
        "tabpages",
        "winsize",
        "help",
        "globals",
        "localoptions",
        "folds"
    }
    vim.cmd("mksession! " .. session_file)
    print("Session saved.")
end

-- Get standardized floating window dimensions
M.get_floating_dimensions = function()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	return {
		width = width,
		height = height,
		row = row,
		col = col,
	}
end

return M
