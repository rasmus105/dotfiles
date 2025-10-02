-- Encoding
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.shell = "zsh"

-- Mouse options
vim.opt.splitkeep = "cursor" -- Keeps cursor visible when splitting windows
-- vim.opt.mouse = "" -- Disable mouse support (except for scrolling)
vim.opt.mousescroll = "ver:1,hor:1" -- Disable scrolling

vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current

vim.opt.nu = true -- enable line numbers by default (toggle with <leader>tl)
vim.opt.relativenumber = true -- enable relative line number by default (toggle with <leader>tL)

vim.opt.wrap = false -- By default don't wrap lines (can be toggle with <leader>tw)

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true
-- Search
vim.opt.hlsearch = true -- Highlight search
vim.opt.incsearch = true

vim.opt.scrolloff = 8 -- Set minimum distance to top/bottom to 8 lines.
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.termguicolors = true

vim.opt.timeoutlen = 500 -- Time to wait for a mapped key sequence
vim.opt.ttimeoutlen = 0 -- Time to wait for a terminal key code (makes exiting Insert mode faster)

vim.g.disable_autoformat = false -- Autoformatting diabled by default (<leader>tf to toggle)

-- Plugins

vim.g.snacks_animate = false

vim.diagnostic.config({ virtual_text = true })
