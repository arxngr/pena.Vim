return
{
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "jay-babu/mason-nvim-dap.nvim",
        "nvim-telescope/telescope-dap.nvim",
        "ldelossa/nvim-dap-projects",
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        local telescope = require("telescope.builtin")

        require("mason-nvim-dap").setup({
            ensure_installed = { "cppdbg", "python", "delve", "node2" },
            automatic_setup = true,
        })

        require("mason-nvim-dap").setup_handlers()

        -- UI setup
        dapui.setup()
        require("nvim-dap-virtual-text").setup()

        -- VSCode .vscode/launch.json support
        require("dap.ext.vscode").load_launchjs(nil, {
            cppdbg = { "c", "cpp" },
            python = { "python" },
            delve = { "go" },
            node2 = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
        })

        -- Auto open/close dap-ui
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

        -- Keymaps
        local map = vim.keymap.set
        map("n", "<F5>", dap.continue, { desc = "DAP: Continue" })
        map("n", "<F10>", dap.step_over, { desc = "DAP: Step Over" })
        map("n", "<F11>", dap.step_into, { desc = "DAP: Step Into" })
        map("n", "<F12>", dap.step_out, { desc = "DAP: Step Out" })
        map("n", "<Leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
        map("n", "<Leader>dB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
            { desc = "DAP: Set Breakpoint w/ condition" })
        map("n", "<Leader>dr", dap.repl.open, { desc = "DAP: REPL" })
        map("n", "<Leader>du", dapui.toggle, { desc = "DAP: Toggle UI" })
        map("n", "<Leader>dl", dap.run_last, { desc = "DAP: Run Last" })
        map("n", "<Leader>ds", telescope.dap.commands, { desc = "DAP: Telescope" })

        -- Run with arguments from launch.json or prompt for custom arguments
        map("n", "<leader>da", function()
            -- Prompt for custom arguments
            local input = vim.fn.input("Debug Arguments: ")

            -- Check if user entered any arguments
            if input and input ~= "" then
                -- Override args in the current launch configuration (from launch.json)
                local config = dap.configurations["python"] or dap.configurations["cppdbg"] or
                dap.configurations["node2"]

                if config then
                    -- Assuming the user is debugging Python, C++, Go, or Node.js
                    -- Set the arguments (override if needed)
                    config[1].args = vim.split(input, "%s+") -- Split the input by spaces (arguments)
                end
            end

            -- Run the debugging session
            dap.run()
        end, { desc = "DAP: Run with Arguments (launch.json or custom)" })

        -- Continue debugging session (like pressing F5)
        map("n", "<leader>dc", dap.continue, { desc = "DAP: Continue Debugging" })
    end,
}
