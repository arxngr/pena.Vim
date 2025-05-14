return { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
        ensure_installed = {
            'c',
            'cpp',
            'asm',
            'lua',
            'python',
            'javascript',
            'typescript',
            'vimdoc',
            'vim',
            'regex',
            'terraform',
            'sql',
            'dockerfile',
            'toml',
            'json',
            'java',
            'groovy',
            'go',
            'gitignore',
            'graphql',
            'yaml',
            'make',
            'cmake',
            'markdown',
            'markdown_inline',
            'bash',
            'tsx',
            'css',
            'html',
        },
refactor = {
    smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = "<leader>cr",
      },
    },
  },
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = {
            enable = true,
        },
        indent = { enable = true},
   incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
    textobjects = {
select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer", -- around function
            ["if"] = "@function.inner", -- inner function
          },
        },
      move = {
        enable = true,
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
        goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
        goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
      },
    },
        keys = {
    { "<c-space>", desc = "Increment Selection" },
    { "<bs>", desc = "Decrement Selection", mode = "x" },
  },
    },
 dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects"
  }
}
