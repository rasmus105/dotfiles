-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "json", "jsonc", "markdown" },
-- 	callback = function()
-- 		vim.opt.conceallevel = 0
-- 	end,
-- })

vim.api.nvim_create_autocmd("CmdlineLeave", {
	pattern = "/,?",
	callback = function()
		vim.defer_fn(function()
			vim.cmd("nohlsearch")
		end, 100) -- Small delay to allow seeing the match briefly
	end,
})
-- Disable autoformatting
vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = "Disable autoformat-on-save",
	bang = true,
})
-- Enable autoformatting
vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = "Re-enable autoformat-on-save",
})
