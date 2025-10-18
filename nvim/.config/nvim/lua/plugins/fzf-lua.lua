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

-- Make integration (simple, non-persistent)
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
    local current_makeprg = vim.opt.makeprg:get()
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
        prompt = 'Select makeprg: ',
        actions = {
            ['default'] = function(selected)
                if #selected > 0 then
                    local makeprg = selected[1]:gsub(" %(current%)", "")
                    vim.opt.makeprg = makeprg
                    vim.notify('Set makeprg: ' .. makeprg, vim.log.levels.INFO)
                end
            end
        },
    })
end

map('n', '\\t', select_makeprg_task, { desc = "Select makeprg task" })
