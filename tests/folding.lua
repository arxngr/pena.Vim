local root = vim.fn.getcwd()
local child = vim.fn.jobstart({ vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-i", "NONE", "-n" }, { rpc = true })
assert(child > 0, "could not start folding UI fixture")
local function lua(code, args)
	return vim.rpcrequest(child, "nvim_exec_lua", code, args or {})
end
local function wait(code, message)
	assert(vim.wait(5000, function() return lua(code) == true end, 20), message)
end
local function key(keys)
	vim.rpcrequest(child, "nvim_input", keys)
end
local ok, err = pcall(function()
	vim.rpcrequest(child, "nvim_ui_attach", 100, 40, { rgb = true })
	lua([[
		vim.opt.rtp:prepend(...)
		for _, plugin in ipairs({ "nvim-ufo", "promise-async", "nvim-treesitter" }) do
			local path = vim.fn.stdpath("data") .. "/lazy/" .. plugin
			assert(vim.fn.isdirectory(path) == 1, "Install " .. plugin .. " before running folding regressions")
			vim.opt.rtp:prepend(path)
		end
		require("core.options")
		-- This fixture exercises folds, not the unrelated Navic winbar provider.
		vim.o.winbar = ""
		vim.cmd("filetype on")
		require("plugins.folding.ufo").config()
		vim.api.nvim_buf_set_name(0, "fold-regression.lua")
		vim.bo.filetype = "lua"
		vim.api.nvim_buf_set_lines(0, 0, -1, false, {
			"local function outer()", "if true then", "return 1", "end", "end", "",
			"local function later()", "return 2", "end",
		})
		assert(vim.treesitter.get_parser(0, "lua"), "Install the Lua Treesitter parser before running folding regressions")
	]], { root })
	wait("return vim.fn.foldlevel(1)>0 and vim.fn.foldlevel(7)>0", "unindented functions did not receive syntax folds")
	key("zc")
	wait("return vim.fn.foldclosed(3)==1 and vim.fn.foldclosedend(1)==5", "zc did not close the complete function")
	key("zo")
	wait("return vim.fn.foldclosed(3)==-1", "zo did not reopen the function")
	key("zM")
	wait("return vim.fn.foldclosed(3)==1 and vim.fn.foldclosed(8)==7", "zM did not close both functions")
	key("zo")
	wait("return vim.fn.foldclosed(1)==-1 and vim.fn.foldclosed(2)==2", "opening the outer fold did not preserve its closed child")
	lua([[vim.api.nvim_buf_set_lines(0, 2, 2, false, { "local function inserted()", "return 3", "end" })]])
	wait("return vim.fn.foldlevel(3)>vim.fn.foldlevel(2)", "editing did not create the new nested syntax fold")
	assert(lua("return vim.fn.foldclosed(1)==-1 and vim.fn.foldclosed(2)==2 and vim.fn.foldclosed(10)==10"),
		"fold refresh lost the user's individually open/closed folds")
	key("zR")
	wait("return vim.fn.foldclosed(3)==-1 and vim.fn.foldclosed(11)==-1", "zR did not reopen refreshed folds")
	print("PASS: syntax folds, individual/all-fold keys, and open/closed state survive structural edits")
	lua([[
		vim.cmd("enew!")
		vim.api.nvim_buf_set_name(0, "fold-regression.txt")
		vim.bo.filetype = "text"
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "section", "    child", "        grandchild", "    sibling", "last" })
	]])
	wait("return vim.fn.foldlevel(2)>0", "missing-parser indent fallback did not create folds")
	key("zM")
	wait("return vim.fn.foldclosed(3)>0", "fallback folds did not close")
	key("zR")
	wait("return vim.fn.foldclosed(3)==-1", "fallback folds did not reopen")
	print("PASS: files without a parser retain functional indent folding")
end)
vim.rpcnotify(child, "nvim_command", "qa!")
vim.fn.jobwait({ child }, 3000)
assert(ok, err)
vim.cmd("qa!")
