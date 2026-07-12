vim.diagnostic.config({
	virtual_text = {
		severity = nil,
		source = false,
		format = function(diagnostic)
			local severity = vim.diagnostic.severity[diagnostic.severity]
			local icon = ({ HINT = " ", INFO = " ", WARN = " ", ERROR = " " })[severity] or "●"

			return string.format("%s %s", icon, diagnostic.message)
		end,
		prefix = "",
		suffix = "",
		spacing = 1,
	},
	signs = false, -- Remove sign column
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})
