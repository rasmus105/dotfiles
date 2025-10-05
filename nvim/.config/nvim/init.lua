local map = vim.keymap.set
vim.g.mapleader = " "

---- Options ----
require("options")

---- Keymaps ----
map("n", "<leader>b", ":w<CR> :so<CR>")
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

-- Always center when moving between matches
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Tab
map("n", "<leader><tab><tab>", ":tabnew<CR>")
map("n", "<leader><tab>q", ":tabclose<CR>")
map("n", "<leader><tab>]", ":tabnext<CR>")
map("n", "<leader><tab>[", ":tabprevious<CR>")

-- Better up/down (wrapped lines will count as multiple)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Toggling
map("n", "<leader>tw", ":set wrap!<CR>")

-- Always go forward/backward (regardless of whether '/' or '?' is used)
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })

-- Better paste
map("v", "p", '"_dP', opts)

-- Fix spelling (picks first suggestion)
map("n", "z0", "1z=", { desc = "Fix word under cursor" })

---- Plugins ----
vim.pack.add({
	
	-- General Utils
	{ src = "https://github.com/nvim-lua/plenary.nvim" },

	-- File
	{ src = "https://github.com/stevearc/oil.nvim" },

	-- Searching & Replacing
	{ src = "https://github.com/ibhagwan/fzf-lua" },
	{ src = "https://github.com/dmtrKovalenko/fff.nvim" },
	{ src = "https://github.com/MagicDuck/grug-far.nvim" },

	-- LSP
	{ src = 'https://github.com/neovim/nvim-lspconfig' },
	{ src = 'https://github.com/mason-org/mason.nvim' },
	{ src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
	{ src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },

	-- Colorschemes & Visuals
	{ src = "https://github.com/nvim-mini/mini.icons" },

	{ src = "https://github.com/vague2k/vague.nvim" },
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
});



---- Plugin Setup & Configuration ----
-- Select colorscheme
vim.cmd(":colorscheme vague")

require('mini.icons').setup()
require('grug-far').setup()
require('oil').setup()
require('fff').setup()

vim.g.fff = {
  lazy_sync = true, -- start syncing only when the picker is open
  prompt = "> ", -- default icon isn't loaded properly
  debug = {
    enabled = true,
    show_scores = true,
  },
}

---- Plugin Mappings ----
-- Find files
map('n', '\\f', function() require('fff').find_files() end,
  { desc = 'FFFind files' })

-- Grep 
map('n', '\\w', function() require('fzf-lua').live_grep() end,
	{ desc = 'Grep words' })

-- Grep word on cursor
map('n', 'gw', function() require('fzf-lua').grep_cword() end, 
	{ desc = 'Grep for word cursor is on' })

-- Search & Replace
map('n', '<leader>g', function() require('grug-far').open() end,
	{ desc = 'Search & Replace' })

-- Oil (file editor)
map('n', '<leader>o', ':Oil<CR>')


---- LSP & Autocmds----
require("lsp")
require("autocmds")
