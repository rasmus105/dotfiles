local dap = require("dap")
dap.adapters.lldb = {
	type = "executable",
	command = "/usr/bin/lldb-vscode",
	name = "lldb",
}
dap.configurations.cpp = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
	},
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>")
vim.keymap.set("n", "<leader>dc", "<cmd>DapContinue<CR>")
vim.keymap.set("n", "<leader>dr", "<cmd>lua require('dapui').open({reset = true})<CR>")
vim.keymap.set("n", "<leader>dt", "<cmd>lua require('dapui').toggle()<CR>")
vim.keymap.set("n", "<leader>da", "<cmd>DapStepOut<CR>")
vim.keymap.set("n", "<leader>di", "<cmd>DapStepInto<CR>")
vim.keymap.set("n", "<leader>do", "<cmd>DapStepOver<CR>")
vim.keymap.set("n", "<leader>de", "<cmd>DapTerminate<CR>")

require("dapui").setup()
