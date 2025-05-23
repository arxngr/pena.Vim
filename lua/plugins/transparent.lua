return {
	"xiyaowong/transparent.nvim",
	config = function()
		require("transparent").setup({
			extra_groups = {
				"NormalFloat", -- for floating windows
				"NvimTreeNormal", -- if using nvim-tree
				"TelescopeNormal", -- if using Telescope
				"FloatBorder",
				"VertSplit",
				"StatusLine",
				"StatusLineNC",
				"NormalNC",
				"SignColumn",
			},
			exclude_groups = {}, -- leave empty or add any you *don't* want transparent
		})
		vim.keymap.set("n", "<leader>ut", function()
			require("transparent").toggle()
		end, { desc = "Toggle Transparency", noremap = true, silent = true })
	end,
}
