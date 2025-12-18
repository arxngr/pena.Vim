return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
			local shell = is_windows and (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell") or "zsh" or "bash"

			require("toggleterm").setup({
				size = function(term)
					if term.direction == "horizontal" then
						return math.floor(vim.o.lines * 0.25)
					elseif term.direction == "vertical" then
						return math.floor(vim.o.columns * 0.3)
					end
				end,
				direction = "float",
				float_opts = {
					border = "rounded",
				},
				start_in_insert = true,
				persist_size = true,
				persist_mode = true,
				close_on_exit = false,
				shell = shell,
			})

			local Terminal = require("toggleterm.terminal").Terminal

			local function create_terminal(opts)
				opts = opts or {}
				local term = Terminal:new(vim.tbl_extend("force", {
					hidden = true,
					close_on_exit = false,
				}, opts))

				return function()
					term:toggle()
				end
			end

			-- Create terminals
			local toggle_float_term = create_terminal({ id = 1, direction = "float" })

			-- Keymaps
			vim.keymap.set("n", "<leader>dt", toggle_float_term, { desc = "Toggle Floating Terminal" })
		end,
	},
}
