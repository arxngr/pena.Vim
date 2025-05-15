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
        build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
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
    },
    opts = function()
        require("overseer").enable_dap()
      end,
    config = function()
      local dap = require("dap")

      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- JS/TS/React
      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch & Debug Chrome",
            url = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({ prompt = "Enter URL: ", default = "http://localhost:3000" }, function(url)
                  if url and url ~= "" then coroutine.resume(co, url) end
                end)
              end)
            end,
            webRoot = vim.fn.getcwd(),
            protocol = "inspector",
            sourceMaps = true,
            userDataDir = false,
          },
        }
      end

      -- Python
      dap.adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
      }
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
      }

      -- Go
      dap.adapters.go = function(callback)
        local port = 38697
        local handle
        local stdout = vim.loop.new_pipe(false)
        handle = vim.loop.spawn("dlv", {
          stdio = { nil, stdout },
          args = { "dap", "-l", "127.0.0.1:" .. port },
          detached = true,
        }, function(code)
          stdout:close()
          handle:close()
          if code ~= 0 then
            print("dlv exited with code", code)
          end
        end)
        vim.defer_fn(function()
          callback({ type = "server", host = "127.0.0.1", port = port })
        end, 100)
      end
      dap.configurations.go = {
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
      }

      dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/bin/OpenDebugAD7",
      }
      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "cppdbg",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtEntry = true,
        },
        {
          name = "Attach to gdbserver :1234",
          type = "cppdbg",
          request = "launch",
          MIMode = "gdb",
          miDebuggerServerAddress = "localhost:1234",
          miDebuggerPath = "/usr/bin/gdb",
          cwd = "${workspaceFolder}",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
    keys = {
      {
        "<leader>da",
        function()
          if not vim.fn.filereadable(".vscode/launch.json") == 1 then
            require("dap.ext.vscode").load_launchjs(nil, {
              ["pwa-node"] = js_based_languages,
              ["chrome"] = js_based_languages,
              ["pwa-chrome"] = js_based_languages,
            })
          end
          require("dap").continue()
        end,
        desc = "Start debugging",
      },
      {
        "<leader>dc",
        function() require("dap").continue() end,
        desc = "Continue",
      },
      {
        "<leader>dO",
        function() require("dap").step_out() end,
        desc = "Step Out",
      },
      {
        "<leader>do",
        function() require("dap").step_over() end,
        desc = "Step Over",
      },
      {
        "<leader>dr",
        function() require("dap").repl.open() end,
        desc = "Open DAP REPL",
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
        function() require("dap").toggle_breakpoint() end,
        desc = "Toggle breakpoint",
      },
{
  "<leader>dw",
  function() require("dap.ui.widgets").hover() end,
  desc = "Hover Variable",
},
    { "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest" },
    },
  },
}
