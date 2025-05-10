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

require('lazy').setup {
    require 'plugins.neotree',
    require 'plugins.lualine',
    require 'plugins.treesitter',
    require 'plugins.telescope',
    require 'plugins.lsp',
    require 'plugins.autocompletion',
    require 'plugins.persistence',
    require 'plugins.bufferline',
    require 'plugins.git',
    require 'plugins.dap',
    require 'plugins.toggleterm',
    require 'plugins.overseer',
    require 'plugins.rainbow-delimiter',
    require 'plugins.which-key',
    require 'plugins.conform',
    require 'plugins.autopair',
    require 'plugins.neotest',
    require 'plugins.trouble',
    require 'plugins.diff',
    require 'plugins.move',
    require 'plugins.colorscheme',
    require 'plugins.visual-multi'

}
