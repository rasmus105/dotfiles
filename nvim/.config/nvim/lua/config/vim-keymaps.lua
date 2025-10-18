local map = vim.keymap.set

-- Change shortcuts for switching & resizing view
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")

map("n", "<C-w>h", "<C-w><")
map("n", "<C-w>l", "<C-w>>")
map("n", "<C-w>j", "<C-w>+")
map("n", "<C-w>k", "<C-w>-")

map("n", "<C-w>H", "<C-w>Hzz")
map("n", "<C-w>L", "<C-w>Lzz")
map("n", "<C-w>J", "<C-w>Jzz")
map("n", "<C-w>K", "<C-w>Kzz")

-- Always center when moving up/down
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Copying
map("n", "<leader>y", '"+y')
map("v", "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')
map("n", "<leader>p", '"+P')


-- Select all
map("n", "<C-a>", "gg<S-v>G")

-- clear highlights
map("n", "<leader>/", ":noh<CR>")

-- Remove
map("n", "q:", "")
map("v", "q:", "")

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
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Tip: Use ]q/[q for moving in quickfix list.
-- useful in combination with Fzf-lua:
--  1. search for files or regex pattern
--  2. press Ctrl+q
--  3. ]q, [q to go to next/prev in the list.
