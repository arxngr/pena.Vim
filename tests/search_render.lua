-- Exercise a real Neovim UI grid, not just syntax/extmark metadata.
local child = vim.fn.jobstart({ vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-n" }, { rpc = true })
assert(child > 0, "could not start rendering fixture")
local function lua(code, args) return vim.rpcrequest(child, "nvim_exec_lua", code, args or {}) end
local ok, err = pcall(function()
	vim.rpcrequest(child, "nvim_ui_attach", 100, 40, { rgb = true })
	lua([[
		vim.opt.rtp:prepend(...)
		vim.o.termguicolors = true
		vim.cmd("syntax enable")
		vim.cmd("colorscheme habamax")
		-- A theme may give QuickFixLine a strong foreground/background.
		vim.api.nvim_set_hl(0, "QuickFixLine", { fg = 0xff0000, bg = 0x0000ff, underline = true })
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_name(buf, "render-fixture.cs")
		vim.bo.filetype = "cs"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "before.AddRange(after);", "before.AddRange(after);" })
		require("core.lsp_results").handler({ word = "AddRange" })({ title = "Global Search: AddRange", items = {
			{ bufnr = buf, lnum = 1, col = 8, end_col = 15, text = "before.AddRange(after);" },
			{ bufnr = buf, lnum = 2, col = 8, end_col = 15, text = "before.AddRange(after);" },
		} })
		_G.render_win = vim.api.nvim_get_current_win()
		vim.wait(20)
	]], { vim.fn.getcwd() })
	local function cells()
		vim.rpcrequest(child, "nvim_command", "redraw!")
		return lua([[
			local rows = {}
			for line = 1, 2 do
				local attrs = {}
				for _, col in ipairs({ 1, 7, 8, 15, 16, 22 }) do
					local pos = vim.fn.screenpos(_G.render_win, line, col)
					assert(pos.row > 0 and pos.col > 0, "result code is not visible")
					local char = vim.fn.screenstring(pos.row, pos.col)
					assert(char == ("before.AddRange(after);"):sub(col, col), "screen position does not point at result code: " .. char)
					attrs[#attrs + 1] = vim.fn.screenattr(pos.row, pos.col)
				end
				rows[#rows + 1] = attrs
			end
			return rows
		]])
	end
	local before = cells()
	lua([[
		local function screenline(row)
			local text = {}
			for col = 1, 100 do text[#text + 1] = vim.fn.screenstring(row, col) end
			return table.concat(text)
		end
		local first = vim.fn.screenpos(_G.render_win, 1, 1).row
		assert(screenline(first - 2):find("render-fixture.cs:1:8", 1, true),
			"the first result's path must be visible above its code")
		assert(screenline(first - 1):find("─", 1, true), "path/code separator is not visible")
		local count_visible = false
		for row = 1, first - 3 do
			if screenline(row):find("2 results", 1, true) then count_visible = true end
		end
		assert(count_visible, "total result count must be visible above the list")
	]])
	lua([[vim.api.nvim_set_hl(0, "QuickFixLine", { fg = 0x00ff00, bg = 0xff00ff, bold = true })]])
	assert(vim.deep_equal(before, cells()), "QuickFixLine colors must not override result code")
	lua([[vim.api.nvim_set_hl(0, "Search", { fg = 0xffcc00, bg = 0x222200, bold = true })]])
	local after = cells()
	for line = 1, 2 do
		for _, col in ipairs({ 1, 2, 5, 6 }) do
			assert(vim.deep_equal(before[line][col], after[line][col]), "changing Search colors recolored text outside AddRange")
		end
		for _, col in ipairs({ 3, 4 }) do
			assert(not vim.deep_equal(before[line][col], after[line][col]), "matched text did not adopt the theme's Search colors")
		end
	end
end)
vim.rpcnotify(child, "nvim_command", "qa!")
vim.fn.jobwait({ child }, 2000)
assert(ok, err)
print("PASS: actual UI grid colors only matched text; selected rows retain syntax colors; theme Search changes propagate")
vim.cmd("qa!")
