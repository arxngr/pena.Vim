local js_based_languages = {
	"typescript",
	"javascript",
	"typescriptreact",
	"javascriptreact",
	"vue",
}

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"microsoft/vscode-js-debug",
				build = "npm install --legacy-peer-deps --no-save --ignore-scripts && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
				version = "1.*",
			},
			{
				"mxsdev/nvim-dap-vscode-js",
				config = function()
					require("dap-vscode-js").setup({
						debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
						adapters = {
							"chrome",
							"pwa-node",
							"pwa-chrome",
							"pwa-msedge",
							"pwa-extensionHost",
							"node-terminal",
						},
					})
				end,
			},
			{
				"leoluz/nvim-dap-go",
			},
		},
		opts = function()
			require("overseer").enable_dap()
		end,
		config = function()
			local dap = require("dap")
			local Terminal = require("toggleterm.terminal").Terminal

			local terminal_defaults = {
				close_on_exit = true,
				hidden = false,
				direction = "horizontal",
			}

			-- Track active terminals by adapter type for cleanup
			local active_terminals = {}

			local function create_debug_terminal(adapter_type, cmd, opts)
				opts = opts or {}
				local term_opts = vim.tbl_extend("force", terminal_defaults, {
					cmd = cmd,
					on_open = opts.on_open,
					on_exit = function(term, job, exit_code, event)
						active_terminals[adapter_type] = nil
						if opts.on_exit then
							opts.on_exit(term, job, exit_code, event)
						end
					end,
				})

				local term = Terminal:new(term_opts)
				active_terminals[adapter_type] = term
				return term
			end

			-- Kill terminal for adapter (used in hot reload)
			local function kill_adapter_terminal(adapter_type)
				local term = active_terminals[adapter_type]
				if term then
					term:shutdown()
					active_terminals[adapter_type] = nil
				end
			end

			-- Expose for autocmd
			_G.dap_kill_adapter_terminal = kill_adapter_terminal
			_G.dap_active_terminals = active_terminals

			local function load_dotenv(filename)
				local env_file = io.open(filename, "r")
				if not env_file then
					return
				end
				for line in env_file:lines() do
					local key, val = line:match("^([%w_]+)%s*=%s*(.*)$")
					if key and val then
						val = val:gsub([["(.*)"]], "%1"):gsub([[\'(.*)\']], "%1")
						vim.fn.setenv(key, val)
					end
				end
				env_file:close()
			end

			local function get_pkg_path(pkg, path)
				pcall(require, "mason")
				local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
				path = path or ""
				return root .. "/packages/" .. pkg .. "/" .. path
			end

			local function create_server_adapter(adapter_type, cmd_fn, opts)
				opts = opts or {}
				local default_port = opts.port
				local startup_delay = opts.delay or 300

				return function(callback, config)
					local port = config.port or default_port or math.random(30000, 45000)

					-- Reuse existing terminal if open
					local existing = active_terminals[adapter_type]
					if existing and existing:is_open() then
						callback({ type = "server", host = "127.0.0.1", port = port })
						return
					end

					local cmd = cmd_fn(port, config)
					local term = create_debug_terminal(adapter_type, cmd, {
						on_open = function()
							vim.defer_fn(function()
								callback({ type = "server", host = "127.0.0.1", port = port })
							end, startup_delay)
						end,
					})
					term:toggle()
				end
			end

			local function launch_json_divider()
				return {
					name = "----- ↓ launch.json configs ↓ -----",
					type = "",
					request = "launch",
				}
			end

			local signs = {
				Stopped = { "👉", "DiagnosticWarn", "DapStoppedLine" },
				Breakpoint = { "🌀", "DiagnosticInfo", nil },
				BreakpointCondition = { "⚡", "DiagnosticInfo", nil },
				BreakpointRejected = { "❌", "DiagnosticError", nil },
				LogPoint = { "📝", "DiagnosticInfo", nil },
				BreakpointDisabled = { "⚪", "DiagnosticHint", nil },
			}

			for name, sign in pairs(signs) do
				sign = type(sign) == "table" and sign or { sign }
				vim.fn.sign_define("Dap" .. name, {
					text = sign[1],
					texthl = sign[2] or "DiagnosticInfo",
					linehl = sign[3],
					numhl = sign[3],
				})
			end

			-- Adapters

			-- JavaScript/TypeScript (pwa-node)
			dap.adapters["pwa-node"] = create_server_adapter("pwa-node", function(port)
				return string.format(
					"node %s %d",
					get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
					port
				)
			end, { port = 8123, delay = 100 })

			-- Go (delve)
			dap.adapters.go = create_server_adapter("go", function(port)
				return string.format(
					"dlv dap --listen=127.0.0.1:%d --log --log-output=dap --build-flags='-gcflags \"all=-N -l\"'",
					port
				)
			end, { delay = 300 })

			-- Python (executable adapter, no terminal needed)
			dap.adapters.python = {
				type = "executable",
				command = "python",
				args = { "-m", "debugpy.adapter" },
			}

			-- C/C++ (executable adapter)
			dap.adapters.cppdbg = {
				id = "cppdbg",
				type = "executable",
				command = vim.fn.stdpath("data") .. "/mason/bin/OpenDebugAD7",
			}

			-- Configurations

			-- JavaScript/TypeScript
			local js_configs = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = vim.fn.getcwd(),
					protocol = "inspector",
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach",
					processId = require("dap.utils").pick_process,
					cwd = vim.fn.getcwd(),
					protocol = "inspector",
				},
				{
					type = "pwa-chrome",
					request = "launch",
					name = "Launch & Debug Chrome",
					url = function()
						local co = coroutine.running()
						return coroutine.create(function()
							vim.ui.input(function(url)
								if url and url ~= "" then
									coroutine.resume(co, url)
								end
							end, { prompt = "Enter URL: ", default = "http://localhost:3000" })
						end)
					end,
					webRoot = vim.fn.getcwd(),
					protocol = "inspector",
					userDataDir = false,
				},
				launch_json_divider(),
			}

			for _, lang in ipairs(js_based_languages) do
				dap.configurations[lang] = js_configs
			end

			-- Python
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = function()
						return vim.fn.exepath("python") or "python"
					end,
				},
				launch_json_divider(),
			}

			-- Go
			dap.configurations.go = {
				{
					type = "go",
					name = "Attach to running",
					request = "attach",
					mode = "remote",
					port = 2345,
					host = "127.0.0.1",
				},
				{
					type = "go",
					name = "Debug",
					request = "launch",
					program = "${file}",
				},
				{
					type = "go",
					name = "Debug test",
					request = "launch",
					mode = "test",
					program = "${file}",
				},
				launch_json_divider(),
			}

			-- C/C++
			dap.configurations.cpp = { launch_json_divider() }
			dap.configurations.c = dap.configurations.cpp

			-- Init
			load_dotenv(".env")
			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
		end,
		keys = {
			{
				"<leader>da",
				function()
					require("dap").continue()
				end,
				desc = "Start debugging",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dq",
				function()
					require("dap").clear_breakpoints()
					vim.notify("Breakpoints cleared", vim.log.levels.INFO)
				end,
				desc = "Clear all breakpoints",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Hover Variable",
			},
			{
				"<leader>td",
				function()
					local dapui = require("dapui")
					local dap = require("dap")
					dap.listeners.after.event_initialized["open-panel-repl"] = function()
						dapui.open()
					end
					require("neotest").run.run({ strategy = "dap" })
				end,
				desc = "Debug Nearest (REPL in panel)",
			},
			{
				"<leader>dx",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate DAP",
			},
		},
	},
}
