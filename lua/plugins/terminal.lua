return {
	{
		"akinsho/toggleterm.nvim",
		config = function()
			local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
			local shell = is_windows and (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell") or "zsh"

			require("toggleterm").setup({
				shell = shell,
				direction = "float",
				float_opts = {
					border = "rounded",
					winblend = 0,
				},
			})
		end,
	},
	{
		"voldikss/vim-floaterm",
	},
}
