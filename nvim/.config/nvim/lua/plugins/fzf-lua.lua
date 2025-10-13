local map = vim.keymap.set

require('fzf-lua').setup({
    winopts = {
        fullscreen = true
    },
    keymap = {
        builtin = {
            true,
            ["<C-d>"] = "preview-half-page-down",
            ["<C-u>"] = "preview-half-page-up",
        },
        fzf = {
            true,
            ["ctrl-d"] = "preview-half-page-down",
            ["ctrl-u"] = "preview-half-page-up",
            ["ctrl-q"] = "select-all+accept",
        },
    }
})

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
