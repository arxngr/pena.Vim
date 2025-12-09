local M = {}

local json_path = vim.fn.stdpath("data") .. "/pena/"
vim.fn.mkdir(json_path, "p")

local function deep_merge(orig, new)
	for k, v in pairs(new) do
		if type(v) == "table" and type(orig[k]) == "table" then
			deep_merge(orig[k], v)
		else
			orig[k] = v
		end
	end
end

function M.load(filename)
	local fullpath = json_path .. filename
	local f = io.open(fullpath, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()
	return vim.json.decode(content)
end

function M.save(filename, tbl)
	local fullpath = json_path .. filename

	-- Load existing content
	local existing = M.load(filename)

	-- Deep merge new values
	deep_merge(existing, tbl)

	-- Write back to file
	local f = io.open(fullpath, "w+")
	if f then
		f:write(vim.json.encode(existing))
		f:close()
	end
end

return M
