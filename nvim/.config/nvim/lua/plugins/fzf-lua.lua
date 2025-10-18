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

local small_window = {
    fullscreen = false,
    height = 0.4,
    width = 0.2,
    row = 0.5,
    col = 0.5,
}

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

-- Fuzzy find quick fix list
map('n', '\\q', function() require('fzf-lua').quickfix() end,
    { desc = 'Quickfix list' })

-- Fuzzy find git diff
map('n', '\\g', function() require('fzf-lua').git_diff() end,
    { desc = 'Current git diff' })

-- Fuzzy find buffer git commits
map('n', '\\b', function() require('fzf-lua').git_bcommits() end,
    { desc = 'Commit history for buffer' })

-- Fuzzy find colorschemes
map('n', '\\c', function()
    require('fzf-lua').colorschemes({
        winopts = small_window
    })
end, { desc = 'Fuzzy find colorschemes' })

-- Grep word on cursor
map('n', 'gw', function() require('fzf-lua').grep_cword() end,
    { desc = 'Grep for word cursor is on' })

map('n', 'gr', function()
    require('fzf-lua').lsp_references()
end, { desc = 'LSP References (fzf-lua)' })

map('n', 'gd', function()
    require('fzf-lua').lsp_definitions()
end, { desc = 'LSP Definitions (fzf-lua)' })

-- Make integration
local standard_makeprg_commands = {
    "make",
    "make clean",
    "make build",
    "make test",
    "cargo check",
    "cargo build",
    "cargo test",
    "cargo run",
    "zig build-exe %",
    "zig build",
    "zig build check",
    "zig build test",
}

local function select_makeprg_task()
    local current_makeprg = vim.opt_global.makeprg:get()
    local options = vim.deepcopy(standard_makeprg_commands)

    -- Add current makeprg to top if it's not in the standard list and not empty
    if current_makeprg and current_makeprg ~= "" and current_makeprg ~= "make" then
        local found = false
        for _, cmd in ipairs(options) do
            if cmd == current_makeprg then
                found = true
                break
            end
        end
        if not found then
            table.insert(options, 1, current_makeprg .. " (current)")
        end
    end

    require('fzf-lua').fzf_exec(options, {
        prompt = '> ',
        actions = {
            ['default'] = function(selected)
                -- Use vim.schedule to defer execution until after fzf closes
                vim.schedule(function()
                    vim.notify("selected makeprg!", vim.log.levels.INFO)

                    if #selected > 0 then
                        local makeprg = selected[1]:gsub(" %(current%)", "")

                        -- Try using vim.cmd instead of vim.opt_global
                        vim.cmd('set makeprg=' .. vim.fn.escape(makeprg, ' \\|"'))

                        -- Alternative: print to messages
                        vim.notify('Makeprg set to: ' .. makeprg, vim.log.levels.INFO)
                    else
                        vim.notify("No selection made", vim.log.levels.WARN)
                    end
                end)
            end
        },
        winopts = small_window,
    })
end

map('n', '\\t', select_makeprg_task, { desc = "Select makeprg task" })
