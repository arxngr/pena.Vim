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
					local max_length = 30
					if #value > max_length then
						value = value:sub(1, max_length) .. "..."
					end
					return variable.name .. " = " .. value
				end,
			},
		},
	},
	-- stylua: ignore
	keys = {
		{ "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
		{ "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
	},
	opts = {
		layouts = {
			{
				elements = {
					{ id = "breakpoints", size = 0.25 },
					{ id = "stacks", size = 0.25 },
					{ id = "watches", size = 0.25 },
				},
				size = 40,
				position = "left",
			},
			{
				elements = {
					-- { id = "console", size = 1.0 },
					{ id = "repl", size = 1.0 },
				},
				size = 10,
				position = "bottom",
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
