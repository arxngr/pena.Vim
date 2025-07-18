local function get_project_root()
	local root_patterns = { ".git", ".hg", ".svn", "package.json", "Makefile" }
	local current_dir = vim.fn.expand("%:p:h")

	for _, pattern in ipairs(root_patterns) do
		local root = vim.fn.finddir(pattern, current_dir .. ";")
		if root ~= "" then
			return vim.fn.fnamemodify(root, ":h")
		end

		root = vim.fn.findfile(pattern, current_dir .. ";")
		if root ~= "" then
			return vim.fn.fnamemodify(root, ":h")
		end
	end

	return vim.fn.getcwd()
end

local function pick_files(opts)
	opts = opts or {}
	if opts.root ~= false then
		opts.cwd = get_project_root()
	end
	require("telescope.builtin").find_files(opts)
end

local function pick_grep(opts)
	opts = opts or {}
	if opts.root ~= false then
		opts.cwd = get_project_root()
	end
	require("telescope.builtin").live_grep(opts)
end

local function pick_grep_string(opts)
	opts = opts or {}
	if opts.root ~= false then
		opts.cwd = get_project_root()
	end
	require("telescope.builtin").grep_string(opts)
end

local function pick_oldfiles(opts)
	opts = opts or {}
	if opts.cwd then
		opts.cwd = vim.fn.getcwd()
	end
	require("telescope.builtin").oldfiles(opts)
end

return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")
		local actions = require("telescope.actions")

		local function open_with_trouble(...)
			local ok, trouble = pcall(require, "trouble.sources.telescope")
			if ok then
				return trouble.open(...)
			else
				-- Fallback to quickfix if trouble is not available
				return actions.send_to_qflist(...)
			end
		end

		local function find_files_no_ignore()
			local action_state = require("telescope.actions.state")
			local line = action_state.get_current_line()
			pick_files({ no_ignore = true, default_text = line })
		end

		local function find_files_with_hidden()
			local action_state = require("telescope.actions.state")
			local line = action_state.get_current_line()
			pick_files({ hidden = true, default_text = line })
		end

		local function find_command()
			if vim.fn.executable("rg") == 1 then
				return { "rg", "--files", "--color", "never", "-g", "!.git" }
			elseif vim.fn.executable("fd") == 1 then
				return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
			elseif vim.fn.executable("fdfind") == 1 then
				return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
			elseif vim.fn.executable("find") == 1 and vim.fn.has("win32") == 0 then
				return { "find", ".", "-type", "f" }
			elseif vim.fn.executable("where") == 1 then
				return { "where", "/r", ".", "*" }
			end
		end

		telescope.setup({
			defaults = {
				prompt_prefix = " ",
				selection_caret = " ",
				-- Always open files in the current buffer
				get_selection_window = function()
					return 0 -- Always use current window
				end,
				mappings = {
					i = {
						["<c-t>"] = open_with_trouble,
						["<a-t>"] = open_with_trouble,
						["<a-i>"] = find_files_no_ignore,
						["<a-h>"] = find_files_with_hidden,
						["<C-Down>"] = actions.cycle_history_next,
						["<C-Up>"] = actions.cycle_history_prev,
						["<C-f>"] = actions.preview_scrolling_down,
						["<C-b>"] = actions.preview_scrolling_up,
					},
					n = {
						["q"] = actions.close,
					},
				},
			},
			pickers = {
				find_files = {
					find_command = find_command,
					hidden = true,
				},
			},
		})

		pcall(telescope.load_extension, "fzf")
		local keymap = vim.keymap.set

		keymap(
			"n",
			"<leader>,",
			"<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
			{ desc = "Switch Buffer" }
		)
		keymap("n", "<leader>/", function()
			pick_grep()
		end, { desc = "Grep (Root Dir)" })
		keymap("n", "<leader>:", "<cmd>Telescope command_history<cr>", { desc = "Command History" })
		keymap("n", "<leader><space>", function()
			pick_files()
		end, { desc = "Find Files (Root Dir)" })

		keymap(
			"n",
			"<leader>fb",
			"<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
			{ desc = "Buffers" }
		)
		keymap("n", "<leader>ff", function()
			pick_files()
		end, { desc = "Find Files (Root Dir)" })
		keymap("n", "<leader>fF", function()
			pick_files({ root = false })
		end, { desc = "Find Files (cwd)" })
		keymap("n", "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Find Files (git-files)" })
		keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent" })
		keymap("n", "<leader>fR", function()
			pick_oldfiles({ cwd = vim.fn.getcwd() })
		end, { desc = "Recent (cwd)" })

		-- Git mappings
		keymap("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "Commits" })
		keymap("n", "<leader>gs", "<cmd>Telescope git_status<CR>", { desc = "Status" })

		-- Search mappings
		keymap("n", '<leader>s"', "<cmd>Telescope registers<cr>", { desc = "Registers" })
		keymap("n", "<leader>sa", "<cmd>Telescope autocommands<cr>", { desc = "Auto Commands" })
		keymap("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Buffer" })
		keymap("n", "<leader>sc", "<cmd>Telescope command_history<cr>", { desc = "Command History" })
		keymap("n", "<leader>sC", "<cmd>Telescope commands<cr>", { desc = "Commands" })
		keymap("n", "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", { desc = "Document Diagnostics" })
		keymap("n", "<leader>sD", "<cmd>Telescope diagnostics<cr>", { desc = "Workspace Diagnostics" })
		keymap("n", "<leader>sg", function()
			pick_grep()
		end, { desc = "Grep (Root Dir)" })
		keymap("n", "<leader>sG", function()
			pick_grep({ root = false })
		end, { desc = "Grep (cwd)" })
		keymap("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "Help Pages" })
		keymap("n", "<leader>sH", "<cmd>Telescope highlights<cr>", { desc = "Search Highlight Groups" })
		keymap("n", "<leader>sj", "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" })
		keymap("n", "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Key Maps" })
		keymap("n", "<leader>sl", "<cmd>Telescope loclist<cr>", { desc = "Location List" })
		keymap("n", "<leader>sM", "<cmd>Telescope man_pages<cr>", { desc = "Man Pages" })
		keymap("n", "<leader>sm", "<cmd>Telescope marks<cr>", { desc = "Jump to Mark" })
		keymap("n", "<leader>so", "<cmd>Telescope vim_options<cr>", { desc = "Options" })
		keymap("n", "<leader>sR", "<cmd>Telescope resume<cr>", { desc = "Resume" })
		keymap("n", "<leader>sq", "<cmd>Telescope quickfix<cr>", { desc = "Quickfix List" })
		keymap("n", "<leader>sw", function()
			pick_grep_string({ word_match = "-w" })
		end, { desc = "Word (Root Dir)" })
		keymap("n", "<leader>sW", function()
			pick_grep_string({ root = false, word_match = "-w" })
		end, { desc = "Word (cwd)" })
		keymap("v", "<leader>sw", function()
			pick_grep_string()
		end, { desc = "Selection (Root Dir)" })
		keymap("v", "<leader>sW", function()
			pick_grep_string({ root = false })
		end, { desc = "Selection (cwd)" })
		keymap("n", "<leader>uC", function()
			builtin.colorscheme({ enable_preview = true })
		end, { desc = "Colorscheme with Preview" })

		keymap("n", "<leader>ss", function()
			-- Check if LSP client is attached
			if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
				vim.notify("No LSP client attached", vim.log.levels.WARN)
				return
			end

			-- Use simpler approach without custom symbols filter
			builtin.lsp_document_symbols()
		end, { desc = "Goto Symbol" })

		keymap("n", "<leader>sS", function()
			if #vim.lsp.get_clients() == 0 then
				vim.notify("No LSP client available", vim.log.levels.WARN)
				return
			end

			builtin.lsp_dynamic_workspace_symbols()
		end, { desc = "Goto Symbol (Workspace)" })
	end,
}
