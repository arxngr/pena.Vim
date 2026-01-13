local M = {}
M.opts = {
	settings = {
		html = {
			format = {
				enable = true,
				wrapLineLength = 120,
				wrapAttributes = "auto",
				templating = true,
				indentInnerHtml = true,
			},
			hover = {
				documentation = true,
				references = true,
			},
			suggest = {
				html5 = true,
			},
			validate = {
				scripts = true,
				styles = true,
			},
			autoClosingTags = true,
			mirrorCursorOnMatchingTag = true,
		},
	},
	on_attach = function(client, bufnr)
		-- HTML LSP doesn't support semantic tokens, but we keep the pattern consistent
		-- Enable tag auto-closing
		if client.server_capabilities.completionProvider then
			client.server_capabilities.completionProvider.resolveProvider = true
		end
	end,
}
return M
