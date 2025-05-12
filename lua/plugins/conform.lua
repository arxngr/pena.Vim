return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      local mason_registry = require("mason-registry")

      local function ensure_tools_installed(tools)
        for _, name in ipairs(tools) do
          if not mason_registry.is_installed(name) then
            local pkg = mason_registry.get_package(name)
            if not pkg:is_installed() then
              pkg:install()
            end
          end
        end
      end

      -- Set up conform (formatter plugin)
      require("conform").setup({
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      })

      -- List of formatters to ensure
      local formatters = {
        "stylua", "black", "gofumpt", "prettier", "shfmt",
        "clang-format", "rustfmt",
      }

      -- List of debug tools / DAP adapters to ensure
      local debug_adapters = {
        "codelldb", "cpptools", "delve", "js-debug-adapter", "node-debug2-adapter", "go-debug-adapter",
                "debugpy"
      }

      -- Ensure all are installed
      ensure_tools_installed(vim.tbl_extend("force", formatters, debug_adapters))
    end,
  },
}
