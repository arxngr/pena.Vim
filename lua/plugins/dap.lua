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

			-- Single shared terminal for all debug adapters
			local debug_term = nil
			local debug_term_port = nil

			local function get_or_create_debug_terminal(cmd, port, opts)
				opts = opts or {}
				local current_win = vim.api.nvim_get_current_win()

				-- Reuse existing terminal if same port and still open
				if debug_term and debug_term:is_open() and debug_term_port == port then
					return debug_term, false -- false = didn't create new
				end

				-- Kill old terminal if exists
				if debug_term then
					debug_term:shutdown()
					debug_term = nil
					debug_term_port = nil
				end

				debug_term = Terminal:new({
					cmd = cmd,
					close_on_exit = true,
					hidden = true,
					direction = "horizontal",
					auto_scroll = false,
					start_in_insert = false,
					on_open = function(term)
						vim.cmd("stopinsert")
						-- Return to original window
						vim.schedule(function()
							if vim.api.nvim_win_is_valid(current_win) then
								vim.api.nvim_set_current_win(current_win)
							end
						end)
						if opts.on_open then
							opts.on_open(term)
						end
					end,
					on_exit = function()
						debug_term = nil
						debug_term_port = nil
					end,
				})

				debug_term_port = port
				return debug_term, true -- true = created new
			end

			local function kill_debug_terminal()
				if debug_term then
					debug_term:shutdown()
					debug_term = nil
					debug_term_port = nil
				end
			end

			_G.dap_kill_debug_terminal = kill_debug_terminal

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

			local function create_server_adapter(cmd_fn, opts)
				opts = opts or {}
				local default_port = opts.port
				local startup_delay = opts.delay or 300

				return function(callback, config)
					local port = config.port or default_port or math.random(30000, 45000)
					local cmd = cmd_fn(port, config)

					local term, is_new = get_or_create_debug_terminal(cmd, port, {
						on_open = function()
							vim.defer_fn(function()
								callback({ type = "server", host = "127.0.0.1", port = port })
							end, startup_delay)
						end,
					})

					if is_new then
						term:open()
					else
						-- Terminal already running, just callback
						callback({ type = "server", host = "127.0.0.1", port = port })
					end
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
			dap.adapters["pwa-node"] = create_server_adapter(function(port)
				return string.format(
					"node %s %d",
					get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
					port
				)
			end, { port = 8123, delay = 100 })

			-- Go (delve)
			dap.adapters.go = create_server_adapter(function(port)
				return string.format(
					"dlv dap --listen=127.0.0.1:%d --log --log-output=dap --build-flags='-gcflags \"all=-N -l\"'",
					port
				)
			end, { delay = 300 })

			dap.adapters.python = create_server_adapter(function(port, config)
				return string.format(
					"python -m debugpy --listen 127.0.0.1:%d --wait-for-client %s",
					port,
					config.program or "${file}"
				)
			end, { delay = 500 })

			-- Python (executable adapter, no terminal needed)
			dap.adapters.python = {
				type = "executable",
				command = "python",
				args = { "-m", "debugpy.adapter" },
			}

			-- C/C++ (executable adapter)
			dap.adapters.codelldb = create_server_adapter(function(port)
				local exe = get_pkg_path("codelldb", "extension/adapter/codelldb")
				return string.format("%s --port %d", exe, port)
			end)

			-- Fallback cppdbg (no terminal)
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
			dap.configurations.cpp = {
				{
					type = "cppdbg",
					request = "launch",
					name = "Launch with GDB",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtEntry = true, -- stop at main
					setupCommands = {
						{
							text = "-enable-pretty-printing",
							description = "Enable pretty printing",
							ignoreFailures = true,
						},
					},
				},
				{
					type = "codelldb",
					request = "launch",
					name = "Launch file",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
				launch_json_divider(),
			}
			dap.configurations.c = dap.configurations.cpp

			local function cleanup_debug_binaries()
				local patterns = {
					"__debug_bin*", -- Go delve
					"__debug_*", -- Generic
				}

				local cwd = vim.fn.getcwd()
				for _, pattern in ipairs(patterns) do
					local files = vim.fn.glob(cwd .. "/" .. pattern, false, true)
					for _, file in ipairs(files) do
						os.remove(file)
					end
				end
			end

			dap.listeners.before.event_terminated["cleanup"] = function()
				kill_debug_terminal()
				cleanup_debug_binaries()
			end

			dap.listeners.before.event_exited["cleanup"] = function()
				kill_debug_terminal()
				cleanup_debug_binaries()
			end

			dap.listeners.before.disconnect["cleanup"] = function()
				kill_debug_terminal()
				cleanup_debug_binaries()
			end

			_G.dap_cleanup_debug_binaries = cleanup_debug_binaries

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
				"<leader>dt",
				function()
					require("dap").terminate()
					if _G.dap_kill_debug_terminal then
						_G.dap_kill_debug_terminal()
					end
					if _G.dap_cleanup_debug_binaries then
						_G.dap_cleanup_debug_binaries()
					end
				end,
				desc = "Terminate DAP",
			},
			{
				"<leader>dR",
				function()
					vim.g.dap_auto_reload_on_save = not vim.g.dap_auto_reload_on_save

					vim.notify("DAP Auto-Reload: " .. tostring(vim.g.dap_auto_reload_on_save), vim.log.levels.INFO)
				end,
				desc = "Toggle DAP Auto Reload",
			},
		},
	},
}
