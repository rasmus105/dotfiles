local M = {}

-- ====================================================================================================
-- Previous Tab Page.
-- ====================================================================================================

local previous_tabpage

vim.api.nvim_create_autocmd("TabLeave", {
	group = vim.api.nvim_create_augroup("UserPreviousTabpage", { clear = true }),
	callback = function()
		previous_tabpage = vim.api.nvim_get_current_tabpage()
	end,
})

function M.previous_tab()
	local current_tabpage = vim.api.nvim_get_current_tabpage()
	local tabpages = vim.api.nvim_list_tabpages()

	if #tabpages <= 1 then
		return
	end

	if previous_tabpage and previous_tabpage ~= current_tabpage and vim.api.nvim_tabpage_is_valid(previous_tabpage) then
		vim.api.nvim_set_current_tabpage(previous_tabpage)
	else
		vim.cmd.tabnext()
	end
end

-- ====================================================================================================
-- Return
-- ====================================================================================================

return M
