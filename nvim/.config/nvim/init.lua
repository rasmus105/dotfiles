local map = vim.keymap.set

---- Options ----
require("options")

---- Keymaps ----
-- all my native vim keymaps
require("vim-keymaps")

---- Plugins ----
-- list all plugins to install
require("vim-pack-add")

---- Plugin Setup & Configuration ----
-- Select and configure colorscheme (also adding keybindings for switching)
require("colorscheme")

require('mini.icons').setup()
require('lualine').setup({})
require('grug-far').setup()
require('fff').setup({})

require("yazi").setup({
    floating_window_scaling_factor = 1,
    yazi_floating_window_zindex = 1,
    yazi_floating_window_border = "none",  -- Remove border for true fullscreen
})

require('fzf-lua').setup({
    winopts = {
        fullscreen = true
    }
})

vim.g.fff = {
    lazy_sync = true, -- start syncing only when the picker is open
    prompt = "> ",    -- default icon isn't loaded properly
    debug = {
        enabled = false,
        show_scores = true,
    },
}

local harpoon = require("harpoon")
harpoon.setup({
    settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
    },
})

local harpoon_list = harpoon:list()

harpoon:extend(require("harpoon.extensions").builtins.highlight_current_file())

-- Override the default menu UI to add number key mappings
local orig_ui_toggle = harpoon.ui.toggle_quick_menu
harpoon.ui.toggle_quick_menu = function(...)
    orig_ui_toggle(...)

    -- Get the harpoon window/buffer if it exists
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(buf)

    -- Check if this is the harpoon menu
    if bufname:match("harpoon") then
        -- Map 1-9 keys in the harpoon buffer
        for i = 1, 9 do
            map(
                "n",
                tostring(i),
                function()
                    harpoon_list:select(i)
                end,
                { buffer = buf, noremap = true, silent = true }
            )
        end
    end
end

---- Plugin Mappings ----
-- Find files
-- fff is currently lacking some functionality such as full screen and next/prev keybindings
-- map('n', '\\f', function() require('fff').find_files() end,
--     { desc = 'FFFind files' })
map('n', '\\f', function() require('fzf-lua').files() end,
    { desc = 'Find files' })

-- Grep
map('n', '\\w', function() require('fzf-lua').live_grep() end,
    { desc = 'Grep words' })

-- Find diagnostics
map('n', '\\d', function() require('fzf-lua').diagnostics_workspace() end,
    { desc = 'Diagnostics' })


-- Grep word on cursor
map('n', 'gw', function() require('fzf-lua').grep_cword() end,
    { desc = 'Grep for word cursor is on' })

map('n', 'gr', function()
    require('fzf-lua').lsp_references()
end, { desc = 'LSP References (fzf-lua)' })

map('n', 'gd', function()
    require('fzf-lua').lsp_definitions()
end, { desc = 'LSP Definitions (fzf-lua)' })

map("n", "<leader>te", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end)

-- Search & Replace
map('n', '<leader>g', function() require('grug-far').open() end,
    { desc = 'Search & Replace' })

-- Yazi
map("n", "<leader>-", ":Yazi<CR>")

-- Harpoon
map("n", "<leader>h", function()
    harpoon_list:add()
end)

map("n", "<S-h>", function()
    harpoon.ui:toggle_quick_menu(harpoon_list)
end)

for i = 1, 9 do
    map("n", "<leader>" .. i, function()
        harpoon_list:select(i)
    end)
end

---- LSP ----
require("lsp")

---- Autocmds ----
require("autocmds")
