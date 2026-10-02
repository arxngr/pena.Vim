return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		cmd = { "RenderMarkdown" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
		keys = {
			{ "<leader>mr", "<cmd>RenderMarkdown buf_toggle<cr>", desc = "Markdown toggle rendering", ft = "markdown" },
			{ "<leader>ms", "<cmd>RenderMarkdown preview<cr>", desc = "Markdown preview split", ft = "markdown" },
		},
	},
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		cmd = { "MarkdownPreview", "MarkdownPreviewToggle", "MarkdownPreviewStop" },
		-- The bundled server supports Windows without requiring a Node provider or Yarn.
		build = function(plugin)
			local package = vim.json.decode(table.concat(vim.fn.readfile(plugin.dir .. "/package.json"), "\n"))
			local platform = vim.fn.has("win32") == 1 and "win"
				or (
					vim.fn.has("mac") == 1 and (vim.uv.os_uname().machine == "arm64" and "macos-arm64" or "macos")
					or "linux"
				)
			local binary = plugin.dir
				.. "/app/bin/markdown-preview-"
				.. platform
				.. (vim.fn.has("win32") == 1 and ".exe" or "")
			if vim.fn.executable(binary) == 1 then
				local installed = vim.system({ binary, "--version" }, { text = true }):wait(10000)
				if installed.code == 0 and vim.trim(installed.stdout) == package.version then
					return
				end
			end
			local command = vim.fn.has("win32") == 1 and { "cmd.exe", "/c", "install.cmd", "v" .. package.version }
				or { "sh", "install.sh", "v" .. package.version }
			local result = vim.system(command, { cwd = plugin.dir .. "/app", text = true }):wait(60000)
			assert(
				result.code == 0,
				"Markdown preview install failed (exit " .. result.code .. "): " .. (result.stderr or "")
			)
		end,
		init = function()
			vim.g.mkdp_auto_start = 0
			vim.g.mkdp_auto_close = 0
			vim.g.mkdp_combine_preview = 1
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		keys = {
			{
				"<leader>mp",
				"<cmd>MarkdownPreviewToggle<cr>",
				desc = "Markdown browser preview (Mermaid)",
				ft = "markdown",
			},
			{ "<leader>mP", "<cmd>MarkdownPreviewStop<cr>", desc = "Markdown stop browser preview", ft = "markdown" },
		},
	},
}
