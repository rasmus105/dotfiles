-- keybindings
vim.keymap.set("n", "[b", "<Cmd>BufferPrevious<CR>")
vim.keymap.set("n", "]b", "<Cmd>BufferNext<CR>")

vim.keymap.set("n", "<leader>bd", "<Cmd>BufferClose<CR>")
vim.keymap.set("n", "<leader>ba", "<Cmd>BufferCloseAllButCurrent<CR>")
-- options
vim.g.bufferline = {
	animation = true,

	auto_hide = false,

	closeable = true,

	maximum_padding = 1,
	maximum_length = 30,
}
