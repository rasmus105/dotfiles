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

-- Search through open buffers
map('n', '\\b', function() require('fzf-lua').buffers() end,
    { desc = 'Diagnostics' })

-- Fuzzy find quick fix list
map('n', '\\q', function() require('fzf-lua').quickfix() end,
    { desc = 'Quickfix list' })

-- Fuzzy find git diff
map('n', '\\g', function() require('fzf-lua').git_diff() end,
    { desc = 'Current git diff' })

-- Fuzzy find buffer git commits (file history)
map('n', '\\h', function() require('fzf-lua').git_bcommits() end,
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
    "zig build run",
}

local function makeprg_picker(subdirectory)
    if subdirectory == "" then
        subdirectory = nil
    end

    local subdirectory_prompt = "🔧 Run in subdirectory..."
    local current_makeprg = vim.opt_global.makeprg:get()
    local options = vim.deepcopy(standard_makeprg_commands)

    -- Add current makeprg to top if it's not in the standard list and not empty
    if current_makeprg and current_makeprg ~= "" then
        table.insert(options, 1, current_makeprg .. " (current)")

        -- remove the standard current makeprg
        for i = #options, 1, -1 do -- Iterate backwards to avoid index issues
            if options[i] == current_makeprg then
                table.remove(options, i)
                break
            end
        end
    end


    if not subdirectory then
        table.insert(options, subdirectory_prompt)
    end

    require('fzf-lua').fzf_exec(options, {
        prompt = subdirectory and string.format("in \"%s\"> ", subdirectory) or '> ',
        actions = {
            ['default'] = function(selected)
                -- Use vim.schedule to defer execution until after fzf closes
                vim.schedule(function()
                    if #selected > 0 then
                        if selected[1] == subdirectory_prompt then
                            vim.ui.input({ prompt = "Subdirectory: " }, function(subdir)
                                if subdir and subdir ~= "" then
                                    makeprg_picker(subdir)
                                end
                            end)
                        else
                            local selected_option = selected[1]:gsub(" %(current%)", "")
                            local makeprg
                            if subdirectory then
                                makeprg = string.format("cd %s && %s", vim.fn.shellescape(subdirectory), selected_option)
                            else
                                makeprg = selected_option
                            end

                            vim.cmd('set makeprg=' .. vim.fn.escape(makeprg, ' \\|"'))
                            vim.notify('Makeprg set to: ' .. makeprg, vim.log.levels.INFO)
                        end
                    else
                        vim.notify("No selection made", vim.log.levels.WARN)
                    end
                end)
            end,
        },
        winopts = small_window,
    })
end

map('n', '\\t', function() makeprg_picker(nil) end, { desc = "Select makeprg task" })
