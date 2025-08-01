require("core.autocmds")
require("core.keymaps")
require("core.options")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	require("plugins.oil"),
	require("plugins.lualine"),
	require("plugins.treesitter"),
	require("plugins.cmp"),
	require("plugins.persistence"),
	require("plugins.bufferline"),
	require("plugins.git"),
	require("plugins.dap"),
	require("plugins.overseer"),
	require("plugins.rainbow-delimiter"),
	require("plugins.conform"),
	require("plugins.neotest"),
	require("plugins.trouble"),
	require("plugins.colorscheme"),
	require("plugins.visual-multi"),
	require("plugins.grug-far"),
	require("plugins.mini"),
	require("plugins.lsp"),
	require("plugins.terminal"),
	require("plugins.snacks"),
	require("plugins.which-key"),
	require("plugins.noice"),
	require("plugins.dap-ui"),
	require("plugins.lush"),
	require("plugins.edgy"),
	require("plugins.transparent"),
	require("plugins.wakatime"),
	require("plugins.color-highlight"),
	require("plugins.navic"),
	require("plugins.ufo"),
})
