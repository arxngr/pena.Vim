return {
	"mfussenegger/nvim-dap",
	keys = {
		{ "<leader>dt", nil },
		{
			"<leader>dx",
			function()
				require("dap").terminate()
			end,
			desc = "Terminate DAP",
		},
	},
	config = function()
		local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
		local shell = is_windows and (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell") or "zsh"

		require("toggleterm").setup({
			size = function(term)
				return math.floor(vim.o.lines * 0.25)
			end,
			direction = "float",
			float_opts = { border = "rounded" },
			start_in_insert = true,
			persist_size = true,
			persist_mode = true,
			close_on_exit = false,
			shell = shell,
		})

		local Terminal = require("toggleterm.terminal").Terminal
		local lazy_term = Terminal:new({
			id = 1,
			direction = "float",
			float_opts = { border = "rounded" },
			hidden = true,
			close_on_exit = false,
		})

		function _G.toggle_lazy_term()
			lazy_term:toggle()
		end

		-- Map <leader>dt globally for floating terminal
		vim.keymap.set("n", "<leader>dt", _G.toggle_lazy_term, { desc = "Toggle Floating Terminal" })
	end,
}
