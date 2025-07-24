local function toggle_toggleterm(bufnr)
	local Terminal = require("toggleterm.terminal")
	if Terminal.get_terminal_by_bufnr then
		local term = Terminal.get_terminal_by_bufnr(bufnr)
		if term then
			term:toggle()
			return true
		end
	end
	return false
end

local function toggle_dap_repl()
	local ok, dap = pcall(require, "dap")
	if ok and dap.repl and dap.repl.toggle then
		dap.repl.toggle()
		return true
	end
	return false
end

local function quit_or_toggle(bufnr)
	local ft = vim.bo[bufnr].filetype

	if ft == "toggleterm" then
		if not toggle_toggleterm(bufnr) then
			vim.cmd("close")
		end
	elseif ft == "dap-repl" then
		if not toggle_dap_repl() then
			vim.cmd("close")
		end
	else
		vim.cmd("close")
		pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
	end
end

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"dap-float",
		"toggleterm",
		"dap-repl",
		"vim",
		"floaterm",
		"oil",
		"terminal",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				quit_or_toggle(event.buf)
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer or toggle terminal/dap-repl",
			})
		end)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "man" },
	callback = function(event)
		vim.bo[event.buf].buflisted = false
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "json", "jsonc", "json5" },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

vim.api.nvim_create_autocmd("User", {
	pattern = "OilActionsPost",
	callback = function(event)
		if event.data.actions.type == "move" then
			Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "alpha", "starter", "dashboard" }, -- Adjust to match your startup plugin
	callback = function()
		vim.keymap.set("n", "c", require("utils").open_config, { desc = "Open config", buffer = true })
		vim.keymap.set("n", "s", function()
			require("persistence").load()
		end, { desc = "Restore session for current dir", buffer = true })
	end,
})

-- Enable cursorline only in the active window
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
	pattern = "*",
	callback = function()
		vim.wo.cursorline = true
	end,
})

vim.api.nvim_create_autocmd({ "WinLeave" }, {
	pattern = "*",
	callback = function()
		vim.wo.cursorline = false
	end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function(args)
		local dap = require("dap")

		local session = dap.session()
		if not session then
			return
		end

		local config = session.config or {}
		local adapter_type = config.type
		local port = config.port or 2345 -- fallback
		local host = config.host or "127.0.0.1"

		-- Patterns per adapter
		local file_matches = {
			go = "%.go$",
			rust = "%.rs$",
			python = "%.py$",
			javascript = "%.js$",
			typescript = "%.ts$",
		}

		local current_file = vim.api.nvim_buf_get_name(args.buf)
		local match_pattern = file_matches[adapter_type]

		if not match_pattern or not current_file:match(match_pattern) then
			return
		end

		-- Helper to wait for port
		local function wait_for_port(host, port, callback, interval, max_tries)
			local tries = 0
			local timer = vim.loop.new_timer()
			timer:start(0, interval or 500, function()
				local socket = vim.loop.new_tcp()
				socket:connect(host, port, function(err)
					if not err then
						timer:stop()
						timer:close()
						socket:close()
						vim.schedule(callback)
					else
						tries = tries + 1
						if tries >= (max_tries or 10) then
							timer:stop()
							timer:close()
							socket:close()
							vim.notify("Timeout waiting for debug adapter on port " .. port, vim.log.levels.WARN)
						else
							socket:close()
						end
					end
				end)
			end)
		end

		-- Restart the debugger
		dap.terminate()
		wait_for_port(host, port, function()
			dap.run(config)
		end)
	end,
})
