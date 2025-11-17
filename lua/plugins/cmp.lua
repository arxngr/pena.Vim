return {
	"hrsh7th/nvim-cmp",
	opts = function(_, opts)
		local cmp = require("cmp")

		opts.snippet = {
			expand = function() end, -- no snippet engine
		}

		opts.mapping = cmp.mapping.preset.insert({
			["<Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_next_item()
				else
					fallback()
				end
			end, { "i", "s" }),

			["<S-Tab>"] = cmp.mapping(function(fallback)
				if cmp.visible() then
					cmp.select_prev_item()
				else
					fallback()
				end
			end, { "i", "s" }),

			["<M-Tab>"] = cmp.mapping(function(fallback) -- Alt+Tab behavior
				if cmp.visible() then
					cmp.select_prev_item()
				else
					fallback()
				end
			end, { "i", "s" }),

			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<C-d>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
		})

		opts.sources = cmp.config.sources({
			{ name = "nvim_lsp" },
			{ name = "buffer" },
			{ name = "path" },
		})

		return opts
	end,
}
