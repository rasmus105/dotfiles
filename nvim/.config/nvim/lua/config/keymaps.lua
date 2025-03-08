local keymap = vim.keymap

-- Do things without affecting the registers -- NEW CHECK
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

-- Increment/decrement - NEW CHECK
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Select all -- NEW
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist -- CHECK
-- keymap.set("n", "<C-m>", "<C-i>", opts)

-- Resize window -- NEW
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

-- Change shortcuts for switching view
keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-l>", "<C-w>l")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-k>", "<C-w>k")

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
