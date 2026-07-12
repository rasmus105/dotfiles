local map = vim.keymap.set
local lazy = require("config.lazy")

local function setup()
	lazy.packadd("test-runner.nvim")

	require("test-runner").setup({
		enabled = false, -- disabled by default
	})
end

lazy.on_cmd({
	"TestRunnerToggle",
	"TestRunnerRunAll",
	"TestRunnerRunAtCursor",
	"TestRunnerRunFile",
}, setup)

map("n", "<leader>tt", ":TestRunnerToggle<CR>")
map("n", "<leader>ra", ":TestRunnerRunAll<CR>")
map("n", "<leader>rc", ":TestRunnerRunAtCursor<CR>")
map("n", "<leader>rf", ":TestRunnerRunFile<CR>")
