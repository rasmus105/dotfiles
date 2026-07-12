local map = vim.keymap.set

local function run_current_file()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("Cannot run an unnamed Julia buffer", vim.log.levels.WARN)
		return
	end

	vim.cmd.update()
	vim.cmd("T julia " .. vim.fn.shellescape(file))
end

vim.api.nvim_buf_create_user_command(0, "JuliaRun", run_current_file, {
	desc = "Run current Julia file",
})

map({ "n", "v", "x" }, "<leader>m", run_current_file, { buffer = true, desc = "julia run" })
