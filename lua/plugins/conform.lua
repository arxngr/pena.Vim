return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      local mason_registry = require("mason-registry")

      local function ensure_formatters_installed(formatters)
        for _, name in ipairs(formatters) do
          if not mason_registry.is_installed(name) then
            local pkg = mason_registry.get_package(name)
            if not pkg:is_installed() then
              pkg:install()
            end
          end
        end
      end

    require("conform").setup({
        format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    })
      -- auto install required formatters
      local all_formatters = {
        "stylua", "black", "gofumpt", "prettier", "shfmt",
        "clang-format", "rustfmt"
      }
      ensure_formatters_installed(all_formatters)
    end,
  },
}
