return {
	{
		"vim-test/vim-test",
		config = function()
			vim.g["test#go#runner"] = "gotest"

			local reused_term_buf = nil
			local reused_term_win = nil

			function _G.VimTestReuseTerm(cmd)
				if reused_term_buf and vim.api.nvim_buf_is_valid(reused_term_buf) then
					if not (reused_term_win and vim.api.nvim_win_is_valid(reused_term_win)) then
						vim.cmd("vsplit")
						reused_term_win = vim.api.nvim_get_current_win()
						vim.api.nvim_win_set_buf(reused_term_win, reused_term_buf)
					end

					local job = vim.b[reused_term_buf].terminal_job_id
					if job then
						vim.api.nvim_chan_send(job, "clear\n" .. cmd .. "\n")
						return
					end
				end

				vim.cmd("vsplit | terminal")
				reused_term_win = vim.api.nvim_get_current_win()
				reused_term_buf = vim.api.nvim_get_current_buf()

				local job = vim.b[reused_term_buf].terminal_job_id
				vim.api.nvim_chan_send(job, cmd .. "\n")
			end

			vim.g["test#custom_strategies"] = { reused = _G.VimTestReuseTerm }
			vim.g["test#strategy"] = "reused"

			vim.keymap.set("n", "<leader>tn", ":TestNearest<CR>", { silent = true })
			vim.keymap.set("n", "<leader>tf", ":TestFile<CR>", { silent = true })
			vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>", { silent = true })
			vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", { silent = true })
			vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>", { silent = true })
		end,
	},
}
