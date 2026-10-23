local M = {}

-- Open config
M.open_config = function()
    vim.cmd("edit $MYVIMRC")
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
