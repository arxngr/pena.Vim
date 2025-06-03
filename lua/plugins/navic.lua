return {
	"SmiteshP/nvim-navic",
	dependencies = { "neovim/nvim-lspconfig" },
	config = function()
		require("nvim-navic").setup({
			highlight = true,
			separator = "  ", -- Customize separator
			depth_limit = 10,
			icons = {
				Class = "󰠱 ",
				Function = "󰊕 ",
				Method = "󰆧 ",
				Variable = "󰀫 ",
				Module = "󰏗 ",
				Namespace = "󰌗 ",
				-- Add more icons as desired
			},
		})
	end,
}
