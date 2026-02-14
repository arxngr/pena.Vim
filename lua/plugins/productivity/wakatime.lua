local function has_wakatime_api_key()
	local cfg_path = vim.fn.expand("~/.wakatime.cfg")
	local f = io.open(cfg_path, "r")
	if not f then
		return false
	end

	local has_key = false
	for line in f:lines() do
		if line:match("^api_key%s*=%s*waka_") or line:match("^api_key%s*=%s*[%w-]+") then
			local key = line:match("=%s*(.*)")
			if key and key ~= "" then
				has_key = true
				break
			end
		end
	end
	f:close()
	return has_key
end

return {
	"wakatime/vim-wakatime",
	lazy = false,
	enabled = has_wakatime_api_key(),
}
