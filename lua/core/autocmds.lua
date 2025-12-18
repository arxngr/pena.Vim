-- Terminal/REPL Toggle Functions

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

-- Autocmd Helper Functions

local function create_autocmd(events, opts)
	vim.api.nvim_create_autocmd(events, opts)
end

local function set_buffer_keymap(buf, mode, key, action, desc)
	vim.keymap.set(mode, key, action, {
		buffer = buf,
		silent = true,
		desc = desc,
	})
end

local function set_buflisted_false(buf)
	vim.bo[buf].buflisted = false
end

-- File Operations

create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

create_autocmd("TextYankPost", {
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

create_autocmd("VimResized", {
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

create_autocmd("BufReadPost", {
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

-- FileType-specific Autocmds

local special_filetypes = {
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
	"fugitive",
	"fugitiveblame",
	"fugitivecommit",
	"fugitivepatch",
	"fugitive_diff",
	"git",
	"M",
}

create_autocmd("FileType", {
	pattern = special_filetypes,
	callback = function(event)
		set_buflisted_false(event.buf)
		vim.schedule(function()
			set_buffer_keymap(event.buf, "n", "q", function()
				quit_or_toggle(event.buf)
			end, "Quit buffer or toggle terminal/dap-repl")
		end)
	end,
})

create_autocmd("FileType", {
	pattern = { "man" },
	callback = function(event)
		set_buflisted_false(event.buf)
	end,
})

local text_filetypes = { "text", "plaintex", "typst", "gitcommit", "markdown" }

create_autocmd("FileType", {
	pattern = text_filetypes,
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

local json_filetypes = { "json", "jsonc", "json5" }

create_autocmd("FileType", {
	pattern = json_filetypes,
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

-- Write Operations

create_autocmd("BufWritePre", {
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

create_autocmd("BufWritePre", {
	pattern = "*.go",
	callback = function()
		local clients = vim.lsp.get_active_clients({ bufnr = 0 })
		if #clients == 0 then
			return
		end

		local client = clients[1]
		local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
		params.context = { only = { "source.organizeImports" } }

		local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
		for _, res in pairs(result or {}) do
			for _, action in pairs(res.result or {}) do
				if action.edit then
					vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
				elseif action.command then
					vim.lsp.buf.execute_command(action.command)
				end
			end
		end
	end,
})

-- Plugin-specific Events

create_autocmd("User", {
	pattern = "OilActionsPost",
	callback = function(event)
		if event.data.actions.type == "move" then
			Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
		end
	end,
})

local startup_filetypes = { "alpha", "starter", "dashboard" }

create_autocmd("FileType", {
	pattern = startup_filetypes,
	callback = function()
		set_buffer_keymap(vim.api.nvim_get_current_buf(), "n", "c", require("utils").open_config, "Open config")
		set_buffer_keymap(vim.api.nvim_get_current_buf(), "n", "s", function()
			require("persistence").load()
		end, "Restore session for current dir")
	end,
})

-- Cursorline Management

create_autocmd({ "InsertLeave", "WinEnter" }, {
	pattern = "*",
	callback = function()
		vim.wo.cursorline = true
	end,
})

create_autocmd("WinLeave", {
	pattern = "*",
	callback = function()
		vim.wo.cursorline = false
	end,
})

-- DAP Auto-reload

local function close_edgy_toggleterm()
	local edgy = require("edgy")
	local win = edgy.get_win()
	if win and win.pos == "bottom" and win.buf_name:match("toggleterm") then
		win:close()
	end
end

local dap_file_patterns = {
	go = "%.go$",
	python = "%.py$",
	["pwa-node"] = "%.[tj]sx?$",
	["pwa-chrome"] = "%.[tj]sx?$",
	cppdbg = "%.[ch]pp?$",
}

create_autocmd("BufWritePost", {
	callback = function(args)
		if not vim.g.dap_auto_reload_on_save then
			return
		end

		local dap = require("dap")
		local session = dap.session()
		if not session then
			return
		end

		local config = session.config or {}
		local adapter_type = config.type
		local current_file = vim.api.nvim_buf_get_name(args.buf)
		local pattern = dap_file_patterns[adapter_type]

		if not pattern or not current_file:match(pattern) then
			return
		end

		local saved_config = vim.deepcopy(config)

		if _G.dap_kill_adapter_terminal then
			_G.dap_kill_adapter_terminal(adapter_type)
		end

		close_edgy_toggleterm()

		dap.terminate(nil, nil, function()
			vim.defer_fn(function()
				dap.run(saved_config)
			end, 200)
		end)
	end,
})

-- Fugitive Buffer Handling
create_autocmd("BufEnter", {
	callback = function(event)
		local bufname = vim.api.nvim_buf_get_name(event.buf)

		if bufname:match("^fugitive:///") then
			set_buffer_keymap(event.buf, "n", "q", function()
				vim.api.nvim_buf_delete(event.buf, { force = true })
			end, "Quit Fugitive buffer")
		end
	end,
})
