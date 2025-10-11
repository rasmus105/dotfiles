local map = vim.keymap.set

---- Configuration ----
require('config.vim-pack')
require('config.options')     -- vim options (i.e. vim.opt.*)
require('config.vim-keymaps') -- vim native keymaps
require('config.colorscheme') -- colorscheme configuration and setup
require('config.lsp')         -- LSP setup, configuration and keymaps
require('config.autocmds')    -- Useful autocommands

---- Plugin ----
require('plugins.harpoon')
require('plugins.fzf-lua')
require('plugins.markview')
require('plugins.lualine')
require('plugins.tabby')
require('plugins.surround')

---- Misc Plugins With Minimal Configuration ----
require('mini.icons').setup()
require('grug-far').setup()
map('n', '<leader>g', function() require('grug-far').open() end,
    { desc = 'Search & Replace' })

require('yazi').setup({
    floating_window_scaling_factor = 1,
    yazi_floating_window_zindex = 1,
    yazi_floating_window_border = 'none', -- Remove border for true fullscreen
})
map('n', '<leader>-', ':Yazi<CR>', { desc = 'Toggle Yazi' })
