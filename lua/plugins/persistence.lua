return
{
    "folke/persistence.nvim",
    event = "BufReadPre", -- load before reading buffers
    opts = {},            -- you can customize options if needed
    keys = {
        { "s", function() require("persistence").load() end, desc = "Restore session for current dir" },
    },
}
