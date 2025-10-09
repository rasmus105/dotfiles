local map = vim.keymap.set

---- Colorscheme configuration ----

require('gruvbox').setup({
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = false,
    italic = {
        strings = false,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = '',  -- can be 'hard', 'soft' or empty string
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = false,
})
-- vim.cmd([[
--     silent! colorscheme gruvbox
--     hi normal guibg=#292522
-- ]])

---- Custom colorschemes ----

local select_custom_gruvbox = function()
    vim.cmd(':set background=dark');
    vim.cmd.colorscheme('gruvbox')
    vim.cmd(':hi normal guibg=#292522')
end


---- Create keybindings for selecting colorschemes ----

local select_background_prefix = '<leader>b'
map('n', select_background_prefix .. 'g', function() select_custom_gruvbox() end,
    { desc = 'Select `gruvbox` colorscheme' })
map('n', select_background_prefix .. 'v', function() vim.cmd.colorscheme('vague') end,
    { desc = 'Select `vague` colorscheme' })
map('n', select_background_prefix .. 'l', function() vim.cmd.colorscheme('catppuccin-latte') end,
    { desc = 'Select `catppuccin-latte` colorscheme' })
map('n', select_background_prefix .. 'm', function() vim.cmd.colorscheme('catppuccin-mocha') end,
    { desc = 'Select `catppuccin-mocha` colorscheme' })

---- Select the default colorscheme ----
select_custom_gruvbox()
