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

-- Always center when moving up/down
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Copying
map("n", "<leader>y", '"+y')
map("v", "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')

-- Select all
map("n", "<C-a>", "gg<S-v>G")

-- clear highlights
map("n", "<leader>/", ":noh<CR>")

-- Remove
map("n", "q:", "")

-- Better indenting (stay in visual mode)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Tab
map("n", "<leader><tab>n", ":tabnew<CR>")
map("n", "<leader><tab>q", ":tabclose<CR>")
map("n", "<leader><tab>l", ":tabnext<CR>")
map("n", "<leader><tab>h", ":tabprevious<CR>")
map("n", "<leader><tab>m", "<C-w>T")

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
