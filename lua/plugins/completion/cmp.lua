---@diagnostic disable: undefined-field
local fn = vim.fn

local source_mapping = {
	nvim_lsp = "[LSP]",
	nvim_lua = "[LUA]",
	luasnip = "[SNIP]",
	buffer = "[BUF]",
	path = "[PATH]",
	treesitter = "[TREE]",
}

-- Custom enable/disable logic
local is_not_comment = function()
	local context = require("cmp.config.context")
	return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
end

local is_not_buftype = function()
	local bt = vim.bo.buftype
	local exclude_bt = { "prompt", "nofile" }
	for _, v in pairs(exclude_bt) do
		if bt == v then
			return false
		end
	end
	return true
end

local is_not_filetype = function()
	local ft = vim.bo.filetype
	local exclude_ft = { "neorepl", "gitcommit", "oil" }
	for _, v in pairs(exclude_ft) do
		if ft == v then
			return false
		end
	end
	return true
end

local is_enabled = function()
	return is_not_comment() and is_not_buftype() and is_not_filetype()
end

local config = function()
	local cmp = require("cmp")
	local cmp_tailwind = require("cmp-tailwind-colors")
	local luasnip = require("luasnip") -- require inside function

	local defaults = require("cmp.config.default")()
	local auto_select = true

	cmp.setup({
		enabled = is_enabled,
		preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
		keyword_length = 2,
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end,
		},
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},
		view = {
			entries = {
				name = "custom",
				selection_order = "near_cursor",
				follow_cursor = true,
			},
		},
		mapping = cmp.mapping.preset.insert({
			["<C-b>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
			["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
			["<C-Space>"] = cmp.mapping.complete(),
			["<CR>"] = cmp.mapping.confirm({ select = auto_select }),
			["<C-y>"] = cmp.mapping.confirm({ select = true }),
			["<S-CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace }),
			["<C-CR>"] = function(fallback)
				cmp.abort()
				fallback()
			end,

			-- Tab to select next item OR jump to next snippet placeholder
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				elseif luasnip.locally_jumpable(1) then
					luasnip.jump(1)
				else
					fallback()
				end
			end, { "i", "s" }),

			-- Shift-Tab to select previous item OR jump to previous snippet placeholder
			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				elseif luasnip.locally_jumpable(-1) then
					luasnip.jump(-1)
				else
					fallback()
				end
			end, { "i", "s" }),
		}),
		sources = cmp.config.sources({
			{ name = "luasnip", group_index = 1 },
			{ name = "nvim_lsp", group_index = 2 },
			{ name = "nvim_lua", group_index = 3 },
			{ name = "treesitter", keyword_length = 4, group_index = 4 },
			{ name = "path", keyword_length = 4, group_index = 4 },
			{
				name = "buffer",
				keyword_length = 3,
				group_index = 5,
				option = {
					get_bufnrs = function()
						local bufs = {}
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							bufs[vim.api.nvim_win_get_buf(win)] = true
						end
						return vim.tbl_keys(bufs)
					end,
				},
			},
		}),
		formatting = {
			format = function(entry, item)
				cmp_tailwind.format(entry, item)
				item.menu = source_mapping[entry.source.name]
				local max_abbr = 40
				local max_menu = 30
				if vim.fn.strdisplaywidth(item.abbr) > max_abbr then
					item.abbr = vim.fn.strcharpart(item.abbr, 0, max_abbr - 1) .. "…"
				end
				if vim.fn.strdisplaywidth(item.menu) > max_menu then
					item.menu = vim.fn.strcharpart(item.menu, 0, max_menu - 1) .. "…"
				end
				return item
			end,
		},
		sorting = defaults.sorting,
		experimental = {
			ghost_text = vim.g.ai_cmp and { hl_group = "CmpGhostText" } or false,
		},
	})
end

return {
	"hrsh7th/nvim-cmp",
	config = config,
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lua",
			"ray-x/cmp-treesitter",
			"saadparwaiz1/cmp_luasnip",
			"js-everts/cmp-tailwind-colors",
		},
	},
	lazy = true,
}
