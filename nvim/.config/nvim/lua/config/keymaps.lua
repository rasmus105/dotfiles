local keymap = vim.keymap

-- Do things without affecting the registers
keymap.set("n", "x", '"_x')
keymap.set("n", "<Leader>p", '"0p')
keymap.set("n", "<Leader>P", '"0P')
keymap.set("v", "<Leader>p", '"0p')
keymap.set("n", "<Leader>c", '"_c')
keymap.set("n", "<Leader>C", '"_C')
keymap.set("v", "<Leader>c", '"_c')
keymap.set("v", "<Leader>C", '"_C')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")


-- Jumplist
-- keymap.set("n", "<C-m>", "<C-i>", opts)

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- check after/plugin/lsp.lua for buffer specific mappings (such as go to definition)
-- also plugin/* files may have keymappings (e.g. telescope.lua)

vim.g.mapleader = " "
-- vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

-- Move lines up/down
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '>-2<CR>gv=gv")

-- Always center when moving up/down
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

-- Always center when moving between matches
keymap.set("n", "n", "nzzzv")
keymap.set("n", "N", "Nzzzv")

-- Space + y to copy globally
keymap.set("n", "<leader>y", '"+y')
keymap.set("v", "<leader>y", '"+y')
keymap.set("n", "<leader>Y", '"+Y')

-- Change all strings matching this string
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])


-- Clear highlights
keymap.set("n", "<leader>/", ":noh<CR>")

-- Disable mouse scrolling
keymap.set("", "<up>", "<nop>", { noremap = true })
keymap.set("", "<down>", "<nop>", { noremap = true })
keymap.set("i", "<up>", "<nop>", { noremap = true })
keymap.set("i", "<down>", "<nop>", { noremap = true })

keymap.set("n", "<leader>tf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	vim.notify("Auto formatting has been " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
end, { desc = "Toggle Autoformatting" })

-- Terminal
-- keymap.set("n", "<C-/>", ":ToggleTerm<CR>")
-- Allow normal keybindings for moving between windows in the terminal
keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })

-- Show diagnostic as float
keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic as float" })
