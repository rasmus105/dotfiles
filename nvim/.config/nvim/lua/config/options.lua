local opt = vim.opt
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

opt.wrap = false          -- don't wrap by default
opt.number = true         -- show line numbers
opt.relativenumber = true -- show relative line numbers
opt.cursorline = false    -- don't highlight current line

-- Search
opt.ignorecase = true
opt.smartcase = true -- case sensitive if uppercase in search
opt.hlsearch = true  -- highlight search results
opt.incsearch = true -- Show matches as you type

-- Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true   -- Use spaces instead of tabs
opt.smartindent = true -- Smart auto-indenting
opt.autoindent = true  -- Copy indent from current line

-- Visual settings
opt.termguicolors = true  -- Enable 24-bit colors
opt.signcolumn = 'no'     -- Always show sign column
opt.showmatch = true      -- Highlight matching brackets
opt.matchtime = 2         -- How long to show matching bracket
opt.cmdheight = 1         -- Command line height
opt.showmode = false      -- Don't show mode in command line
opt.pumheight = 10        -- Popup menu height
opt.pumblend = 10         -- Popup menu transparency
opt.winblend = 0          -- Floating window transparency
opt.completeopt = 'menu,menuone,noselect'
opt.conceallevel = 2      -- Hide * markup for bold and italic, but not markers with substitutions
opt.concealcursor = ''    -- Don't hide cursor line markup
opt.synmaxcol = 300       -- Syntax highlighting limit
opt.ruler = false         -- Disable the default ruler
opt.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
opt.winminwidth = 5       -- Minimum window width
opt.winborder = 'rounded' -- Show border around windows

-- File handling
opt.backup = false                            -- Don't create backup files
opt.writebackup = false                       -- Don't create backup before writing
opt.swapfile = false                          -- Don't create swap files
opt.undofile = true                           -- Persistent undo
opt.undolevels = 10000
opt.undodir = vim.fn.expand('~/.vim/undodir') -- Undo directory
opt.updatetime = 300                          -- Faster completion
opt.timeoutlen = 300                          -- Lower than default (1000) to quickly trigger which-key
opt.ttimeoutlen = 0                           -- Key code timeout
opt.autoread = true                           -- Auto reload files changed outside vim
opt.autowrite = true                          -- Auto save

-- Behavior Settings
opt.hidden = true                  -- Allow hidden buffers
opt.errorbells = false             -- No error bells
opt.backspace = 'indent,eol,start' -- Better backspace behavior
opt.autochdir = false              -- Don't auto change directory
opt.path:append('**')              -- include subdirectories in search
opt.mouse = 'a'                    -- Enable mouse support
opt.mousescroll = 'ver:1,hor:1'
-- opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus' -- Sync with system clipboard
opt.modifiable = true  -- Allow buffer modifications
opt.encoding = 'UTF-8' -- Set encoding

-- Folding settings
opt.smoothscroll = true
vim.wo.foldmethod = 'expr'
opt.foldlevel = 99             -- Start with all folds open
opt.formatoptions = 'jcroqlnt' -- default: tcqj
opt.grepformat = '%f:%l:%c:%m'
opt.grepprg = 'rg --vimgrep'   -- use ripgrep instead of standard grep

-- Split behavior
opt.splitbelow = true -- Horizontal splits go below
opt.splitright = true -- Vertical splits go right
opt.splitkeep = 'screen'


-- Command-line completion
opt.wildmenu = true
opt.wildmode = 'longest:full,full'
opt.wildignore:append({ '*.o', '*.obj', '*.pyc', '*.class', '*.jar' })

-- Better diff options
opt.diffopt:append('linematch:60')

-- Performance improvements
opt.redrawtime = 10000
opt.maxmempattern = 20000

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand('~/.vim/undodir')
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, 'p')
end

opt.laststatus = 3
opt.list = false -- Show some invisible characters (tabs...

vim.diagnostic.config({
    virtual_text = {
        severity = nil,
        source = false,
        format = function(diagnostic)
            local severity = vim.diagnostic.severity[diagnostic.severity]
            local icon = ({
                HINT = ' ',
                INFO = ' ',
                WARN = ' ',
                ERROR = ' ',
            })[severity] or '●'

            return string.format('%s %s', icon, diagnostic.message)
        end,
        prefix = '',
        suffix = '',
        spacing = 1,
    },
    signs = false, -- Remove sign column
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})
