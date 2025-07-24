return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
			local shell = is_windows and (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell") or "zsh"

			require("toggleterm").setup({
				size = function(term)
					return math.floor(vim.o.lines * 0.25)
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
				on_exit = function(term, job_exit_code, _)
					if job_exit_code == 0 then
						vim.schedule(function()
							vim.cmd("bd! " .. term.bufnr)
						end)
					else
						vim.notify("Terminal exited with code " .. job_exit_code, vim.log.levels.WARN)
					end
				end,
			})

			-- Reusable floating terminal with fixed ID
			local Terminal = require("toggleterm.terminal").Terminal
			local lazy_term = Terminal:new({
				id = 1,
				direction = "float",
				float_opts = {
					border = "rounded",
				},
				hidden = true,
				close_on_exit = false,
			})

			function _G.toggle_lazy_term()
				lazy_term:toggle()
			end

			vim.keymap.set("n", "<leader>dt", toggle_lazy_term, { desc = "Toggle Floating Terminal" })
		end,
	},
}
