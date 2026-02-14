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
	keys = {
		{
			"<leader>de",
			function()
				require("dapui").eval()
			end,
			desc = "Debug Evaluate",
			mode = { "n", "v" },
		},
		{
			"<leader>ds",
			function()
				require("dapui").float_element("stacks", { enter = true, position = "center" })
			end,
			desc = "Debug Stacks Float",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Debug REPL Toggle",
		},
		{
			"<leader>dlb",
			function()
				require("dapui").float_element("breakpoints", { enter = true, position = "center" })
			end,
			desc = "Debug Breakpoints Float",
		},
		{
			"<leader>dh",
			function()
				require("dapui").float_element("watches", { enter = true, position = "center" })
			end,
			desc = "Debug Watches Float",
		},
		{
			"<leader>dv",
			function()
				require("dapui").float_element("scopes", { enter = true, position = "center" })
			end,
			desc = "Debug Scopes Float",
		},
	},
	opts = function()
		local utils = require("core.utils")
		local dims = utils.get_floating_dimensions()
		return {
			layouts = {},
			floating = {
				max_height = 0.8, -- DAPUI uses relative ratio for these
				max_width = 0.8,
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
		}
	end,
	config = function(_, opts)
		local dap = require("dap")
		local dapui = require("dapui")
		dapui.setup(opts)

		dap.listeners.before.event_initialized["dapui_config"] = function()
			dapui.open({})
		end
		dap.listeners.after.event_terminated["dapui_config"] = function()
			dap.disconnect({ terminateDebuggee = true }) -- force terminate debuggee
		end
		dap.listeners.before.event_exited["dapui_config"] = function() end
	end,
}
