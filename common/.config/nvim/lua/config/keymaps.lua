local map = vim.keymap.set
local functions = require("config.keymaps.functions")

-- Use "x" for Visual-only maps so typing can replace selected snippet placeholders.

-- Command shortcuts
map({ "n", "x" }, "<leader>n", ":norm ", { desc = "enter norm command" })
map({ "n", "x" }, "<leader>q", ":q<CR>", { desc = "quit" })
map({ "n", "x" }, "<leader>x", ":wqa!<CR>", { desc = "force quit all" })
map({ "n", "x" }, "<leader>l", ":update<CR>:source<CR>", { desc = "Update and source lua file" })
map({ "n", "x" }, "<leader>,", ":tabnew<CR>:term<CR>i", { desc = "Open terminal" })
map({ "n", "x" }, "<leader>.", ":edit!<CR>", { desc = "Reload current file" })
map({ "n", "x" }, "<CR>", ":T ", { desc = "Execute terminal command" })
map({ "n", "x" }, "<leader>s", ":wa<CR>", { desc = "Save all files" })

-- Change shortcuts for switching & resizing view
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")

map("n", "<C-w>h", "5<C-w><")
map("n", "<C-w>l", "5<C-w>>")
map("n", "<C-w>j", "5<C-w>+")
map("n", "<C-w>k", "5<C-w>-")

map("n", "<C-w>H", "<C-w>Hzz")
map("n", "<C-w>L", "<C-w>Lzz")
map("n", "<C-w>J", "<C-w>Jzz")
map("n", "<C-w>K", "<C-w>Kzz")

-- make moving in quicklist less disorienting
map("n", "]q", ":cnext<CR>zz")
map("n", "[q", ":cprev<CR>zz")

-- Always center when moving up/down or jumping
map("n", "<C-d>", function()
	vim.cmd("normal! " .. vim.keycode("<C-d>") .. "zz")
end, { desc = "Scroll down and center" })
map("n", "<C-u>", function()
	vim.cmd("normal! " .. vim.keycode("<C-u>") .. "zz")
end, { desc = "Scroll up and center" })
map("n", "<C-f>", "<C-f>zz")
map("n", "<C-b>", "<C-b>zz")
map("n", "<C-o>", "<C-o>zz")
map("n", "<C-i>", "<C-i>zz")

for _, key in ipairs({
	"zF",
	"zd",
	"zD",
	"zE",
	"zo",
	"zO",
	"zc",
	"zC",
	"za",
	"zA",
	"zv",
	"zx",
	"zX",
	"zm",
	"zM",
	"zr",
	"zR",
	"zn",
	"zN",
	"zi",
	"zj",
	"zk",
}) do
	map("n", key, key .. "zz")
end

-- Copying
map({ "n", "x" }, "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')
map("n", "<leader>p", '"+p')
map("n", "<leader>d", '"+d')

-- Select all
map("n", "<leader>a", "gg<S-v>G")

-- clear highlights
map("n", "<leader>/", ":noh<CR>")

-- Remove command history list
map({ "n", "x" }, "q:", "")

-- Better indenting (stay in visual mode)
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Tab

map("n", "<tab>", functions.previous_tab)
map("n", "<leader><tab>n", ":tabnew<CR>")
map("n", "<leader><tab>q", ":tabclose<CR>")
map("n", "<leader><tab>l", ":tabnext<CR>")
map("n", "<leader><tab>h", ":tabprevious<CR>")
map("n", "<leader><tab>m", "<C-w>T")
for i = 1, 9 do
	map("n", "<leader><tab>" .. i, ":tabn " .. i .. "<CR>")
end

-- Better up/down (wrapped lines will count as multiple)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Toggling
map("n", "<leader>tw", ":set wrap!<CR>")

-- Always go forward/backward (regardless of whether '/' or '?' is used)
-- and center after moving
map("n", "n", "'Nn'[v:searchforward].'zzzv'", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zzzv'", { expr = true, desc = "Prev Search Result" })

-- Better paste
map("x", "p", '"_dP')

-- Fix spelling (picks first suggestion)
map("n", "z0", "1z=", { desc = "Fix word under cursor" })

-- Move lines up/down
map("x", "J", ":m '>+1<CR>gv=gv")
map("x", "K", ":m '>-2<CR>gv=gv")

-- Change all strings matching this string
map("n", "<leader>w", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Replace word in buffer",
})
map("x", "<leader>w", [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Replace word in selected lines",
})

-- Tip: Use ]q/[q for moving in quickfix list.
-- useful in combination with Fzf-lua:
-- 1. search for files or regex pattern
-- 2. press Ctrl+q
-- 3. ]q, [q to go to next/prev in the list.

-- binds Ctrl + E in insert mode to go the the end of the line, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-e>", "<End>")

-- binds Ctrl + A in insert mode to go the the start of the line, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-a>", "<Home>")

-- binds Ctrl + b in insert mode to go backward 1 character, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-b>", "<Left>")

-- binds Ctrl + f in insert mode to go forward 1 character, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-f>", "<Right>")

-- Snippet placeholders use Select mode; leave it without replacing their text.
for key, motion in pairs({
	["<C-e>"] = "<End>",
	["<C-a>"] = "<Home>",
	["<C-b>"] = "<Left>",
	["<C-f>"] = "<Right>",
}) do
	map("s", key, "<Esc>i" .. motion)
end

-- make ESC behave similar to regular ESC in terminals
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal" })
