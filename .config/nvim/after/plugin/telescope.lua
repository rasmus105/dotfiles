local builtin = require("telescope.builtin")

-- telescope keymappings
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fw", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fa", function()
	builtin.find_files({
		find_command = { "rg", "--files", "--hidden" },
	})
end)
-- telescope file browser keymappings
-- vim.keymap.set('n', '<leader>fd', '<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>')

-- telescope file browser
require("telescope").setup() -- {
--    extensions = {
--      file_browser = {
--        theme = 'gruvbox' ,
--      hijack_netrw = true,
--},
--},
--}

-- require("telescope").load_extension "file_browser"
