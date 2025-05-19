return {
	"rcarriga/nvim-dap-ui",
	dependencies = {
		"nvim-neotest/nvim-nio",
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {
				enabled = true,
				display_callback = function(variable, _buf, _stackframe, _node)
					local value = variable.value or ""
					local max_length = 25
					if #value > max_length then
						value = value:sub(1, max_length) .. "..."
					end
					return " = " .. value
				end,
			},
		},
	},
	-- stylua: ignore
	keys = {
		{ "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
		{ "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
        { "<leader>ds", function() require("dapui").float_element("stacks", { enter = true, position = "center" }) end, desc = "Stacks Float" },
        { "<leader>dr", function() require("dapui").float_element("repl", { enter = true, position = "center" }) end, desc = "REPL Float" },
        { "<leader>dlb", function() require("dapui").float_element("breakpoints", { enter = true, position = "center" }) end, desc = "Breakpoints Float" },
        { "<leader>dh", function() require("dapui").float_element("watches", { enter = true, position = "center" }) end, desc = "Watches Float" },
        { "<leader>dv", function() require("dapui").float_element("scopes", { enter = true, position = "center" }) end, desc = "Scopes Float" },
        { "<leader>dt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "ToggleTerm" },
	},
	opts = {
		layouts = {}, -- Disable sidebar/bottom splits
		floating = {
			max_height = 0.7,
			max_width = 0.7,
			mappings = {
				close = { "q", "<Esc>" },
			},
		},
	},
	config = function(_, opts)
		local dap = require("dap")
		local dapui = require("dapui")
		dapui.setup(opts)

		dap.listeners.before.event_initialized["dapui_config"] = function()
			dapui.open({})
		end
		dap.listeners.after.event_terminated["dapui_config"] = function() end
		dap.listeners.before.event_exited["dapui_config"] = function() end
	end,
}
