local map = vim.keymap.set

-- Command shortcuts
map({ "n", "v", "x" }, "<leader>n", ":norm<CR>", { desc = "enter norm command" })
map({ "n", "v", "x" }, "<leader>s", ":update<CR>", { desc = "update" })
map({ "n", "v", "x" }, "<leader>o", ":update<CR>:source %<CR>", { desc = "write and source current file" })
map({ "n", "v", "x" }, "<leader>q", ":q<CR>", { desc = "quit" })
map({ "n", "v", "x" }, "<leader>Q", ":wqa<CR>", { desc = "quit all" })
map({ "n", "v", "x" }, "<leader>m", ":make<CR>", { desc = "make" })

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

-- Always center when moving up/down
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Copying
map({ "n", "v" }, "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')
map("n", "<leader>p", '"+p')
map("n", "<leader>d", '"+d')

-- Select all
map("n", "<leader>a", "gg<S-v>G")

-- clear highlights
map("n", "<leader>/", ":noh<CR>")

-- Remove command history list
map({ "n", "v" }, "q:", "")

-- Better indenting (stay in visual mode)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Tab
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
map("v", "p", '"_dP')

-- Fix spelling (picks first suggestion)
map("n", "z0", "1z=", { desc = "Fix word under cursor" })

-- Ctrl+Tab to go to previous
map("c", "<C-Tab>", "<S><Tab>")

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '>-2<CR>gv=gv")

-- Change all strings matching this string
map("n", "<leader>w", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Tip: Use ]q/[q for moving in quickfix list.
-- useful in combination with Fzf-lua:
--  1. search for files or regex pattern
--  2. press Ctrl+q
--  3. ]q, [q to go to next/prev in the list.

-- binds Ctrl + E in insert mode to go the the end of the line, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-e>", '<End>')

-- binds Ctrl + E in insert mode to go the the end of the line, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-a>", '<Home>')

-- binds Ctrl + b in insert mode to go backward 1 character, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-b>", "<Left>")

-- binds Ctrl + f in insert mode to go forward 1 character, providing consistency with
-- terminal/shell experience (that is the normal behavior)
map({ "c", "i" }, "<C-f>", "<Right>")
