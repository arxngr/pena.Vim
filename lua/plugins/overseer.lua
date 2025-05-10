return {
    "stevearc/overseer.nvim",
    opts = {},
    config = function()
        require("overseer").setup({
            dap = true,
            strategy = {
                "toggleterm",
            },
        })
        require("overseer").enable_dap()
    end,
}
