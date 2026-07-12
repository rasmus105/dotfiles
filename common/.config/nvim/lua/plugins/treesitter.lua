local lazy = require("config.lazy")

local setup = lazy.once("treesitter", function()
	lazy.packadd("nvim-treesitter")
	require("nvim-treesitter").setup({
		install_dir = vim.fn.stdpath("data") .. "/site",
	})
end)

lazy.on_event("FileType", "Treesitter", function(args)
	if not vim.api.nvim_buf_is_valid(args.buf) then
		return
	end

	setup()

	local ok = pcall(vim.treesitter.start, args.buf)
	if not ok then
		return
	end

	if vim.api.nvim_get_current_buf() == args.buf then
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end
	vim.bo[args.buf].syntax = ""
end, { schedule = true })
