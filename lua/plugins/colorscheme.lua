return {
    "zaldih/themery.nvim",
    dependencies = {
{
  "navarasu/onedark.nvim",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('onedark').setup {
      style = 'darker'
    }
    -- Enable theme
    require('onedark').load()
  end
},
        {
  'uloco/bluloco.nvim',
  lazy = true,
  priority = 1000,
  dependencies = { 'rktjmp/lush.nvim' },
  config = function()
    -- your optional config goes here, see below.
  end,
},
{ "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false, priority = 1000 },
{ 
  'olivercederborg/poimandres.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('poimandres').setup {
      -- leave this setup function empty for default config
      -- or refer to the configuration section
      -- for configuration options
    }
  end,

},
        { "akinsho/horizon.nvim",            lazy = false,
 version = "*" },
        { "miikanissi/modus-themes.nvim", priority = 1000 , lazy = false},
    },
 keys = {
      { "<leader>uc", "<cmd>Themery<CR>", desc = "Toggle Themery" },
    },
    lazy = false,
    config = function()
      require("themery").setup({

  themes = {"onedark", "bluloco", "moonfly", "poimandres", "horizon", "modus"}
      })
    end
  }
