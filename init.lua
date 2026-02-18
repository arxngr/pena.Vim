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
	require("plugins.file-explorer.oil"),
	require("plugins.ui.lualine"),
	require("plugins.syntax.treesitter"),
	require("plugins.completion.cmp"),
	require("plugins.utilities.persistence"),
	require("plugins.ui.bufferline"),
	require("plugins.git.git"),
	require("plugins.debugging.dap"),
	require("plugins.debugging.overseer"),
	require("plugins.debugging.chainsaw"),
	require("plugins.ui.rainbow-delimiter"),
	require("plugins.formatting.conform"),
	require("plugins.testing.test"),
	require("plugins.diagnostics.trouble"),
	require("plugins.colorscheme.colorscheme"),
	require("plugins.editing.visual-multi"),
	require("plugins.search.grug-far"),
	require("plugins.utilities.mini"),
	require("plugins.completion.lsp"),
	require("plugins.terminal.terminal"),
	require("plugins.utilities.snacks"),
	require("plugins.ui.which-key"),
	require("plugins.ui.noice"),
	require("plugins.debugging.dap-ui"),
	require("plugins.colorscheme.lush"),
	require("plugins.colorscheme.ccc"),
	require("plugins.ui.edgy"),
	require("plugins.ui.transparent"),
	require("plugins.productivity.wakatime"),
	require("plugins.ui.color-highlight"),
	require("plugins.ui.navic"),
	require("plugins.folding.ufo"),
})
