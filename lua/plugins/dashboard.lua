return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local version = vim.version()
    local nvim_version = string.format("  Neovim v%d.%d.%d", version.major, version.minor, version.patch)

    vim.api.nvim_set_hl(0, 'DashboardHeader', { fg = '#0098dd' })  -- Tomato color for header
 require("dashboard").setup({
   theme = 'hyper',
   config = {
    header = {
    [[  /$$$$$$                      /$$    /$$ /$$$$$$ /$$      /$$]],
    [[ /$$__  $$                    | $$   | $$|_  $$_/| $$$    /$$$]],
    [[| $$  \ $$ /$$$$$$$           | $$   | $$  | $$  | $$$$  /$$$$]],
    [[| $$$$$$$$| $$__  $$          |  $$ / $$/  | $$  | $$ $$/$$ $$]],
    [[| $$__  $$| $$  \ $$           \  $$ $$/   | $$  | $$  $$$| $$]],
    [[| $$  | $$| $$  | $$            \  $$$/    | $$  | $$\  $ | $$]],
    [[| $$  | $$| $$  | $$ /$$         \  $/    /$$$$$$| $$ \/  | $$]],
    [[|__/  |__/|__/  |__/|__/          \_/    |______/|__/     |__/]],
     "",
     nvim_version,
     "🛠  Configured by Ardi Nugraha",
     "",
    },
    buttons = {
     { "  New File", "enew", "n" },
     { "  Find File", "Telescope find_files", "f" },
     { "  Recent Files", "Telescope oldfiles", "r" },
     { "  Config", "edit ~/.config/nvim/init.lua", "c" },
     { "  Quit", "qa", "q" },
    },
    footer = {
     "",
     "🔥 Happy hacking!",
    },
   },
  })
  end,
}
