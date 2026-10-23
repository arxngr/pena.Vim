-- Upstream #48 normalizes a missing key into a Windows path, then warns about it.
-- Guard the absent value in the affected release; explicit deprecated options still warn.
local function fix_nil_theme_path(plugin)
	local path = plugin.dir .. "/lua/themery/config.lua"
	local lines = vim.fn.readfile(path)
	local old = table.concat(lines, "\n")
	local needle = "\tlocal path = configSettings.themeConfigFile\n\tlocal normalizedPath"
	local first, last = old:find(needle, 1, true)
	if not first then return end
	local fixed = "\tlocal path = configSettings.themeConfigFile\n"
		.. "\tif path == nil or path == vim.NIL then return end\n\tlocal normalizedPath"
	local updated = old:sub(1, first - 1) .. fixed .. old:sub(last + 1)
	vim.fn.writefile(vim.split(updated, "\n", { plain = true }), path)
end

return {
	"zaldih/themery.nvim",
	dependencies = {
		{
			"navarasu/onedark.nvim",
			priority = 1000, -- make sure to load this before all the other start plugins
			config = function()
				require("onedark").setup({
					style = "darker",
				})
				require("onedark").load()
			end,
		},
		{
			"arxngr/tinta.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("tinta").setup({ palette = "tinta-darker-cool" })
			end,
		},
		{
			"uloco/bluloco.nvim",
			lazy = false,
			priority = 1000,
			dependencies = { "rktjmp/lush.nvim" },
			opts = {},
		},
	},
	keys = {
		{ "<leader>uc", "<cmd>Themery<CR>", desc = "Toggle Themery" },
	},
	lazy = false,
	build = fix_nil_theme_path,
	config = function(plugin)
		fix_nil_theme_path(plugin)
		require("themery").setup({
			themes = {
				{
					name = "OneDark",
					colorscheme = "onedark",
					before = [[
						vim.o.background = "dark"
						require("onedark").setup({ style = "darker" })
					]],
				},
				{
					name = "Tinta",
					colorscheme = "tinta",
					before = [[
						vim.o.background = "dark"
						require("tinta").setup({ palette = "tinta-darker-cool" })
					]],
				},
				{
					name = "Bluloco Dark",
					colorscheme = "bluloco-dark",
					before = [[
						vim.o.background = "dark"
					]],
				},
				{
					name = "Bluloco Light",
					colorscheme = "bluloco-light",
					before = [[
						vim.o.background = "light"
					]],
				},
			},
		})
	end,
}
