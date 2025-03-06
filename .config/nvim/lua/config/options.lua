-- CHECK THIS
-- vim.opt.encoding = "utf-8"
-- vim.opt.fileencoding = "utf-8"

vim.opt.shell = "zsh"
vim.opt.wrap = false -- No Wrap lines
--vim.opt.backspace = { "start", "eol", "indent" }
--vim.opt.path:append({ "**" }) -- Finding files - Search down into subfolders
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current
vim.opt.splitkeep = "cursor" -- Keeps cursor visible when splitting windows
vim.opt.mouse = "" -- Disable mouse support (except for scrolling)
vim.opt.mousescroll = "ver:0,hor:0" -- Disable scrolling

-- Undercurl -- CHECK
-- vim.cmd([[let &t_Cs = "\e[4:3m"]])
-- vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Add asterisks in block comments - Figure out what this is
-- vim.opt.formatoptions:append({ "r" })

-- vim.cmd([[au BufNewFile,BufRead *.astro setf astro]])
-- vim.cmd([[au BufNewFile,BufRead Podfile setf ruby]])

vim.g.lazyvim_prettier_needs_config = true
vim.g.lazyvim_picker = "telescope"
vim.g.lazyvim_cmp = "blink.cmp"

-- My config below

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

-- vim.opt.hlsearch = false
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.termguicolors = true

-- [[
-- Plugins
-- ]]

vim.g.snacks_animate = false

vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
