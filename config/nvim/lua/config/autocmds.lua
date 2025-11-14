-- Highlight on yank (neet visual feedback when yanking)
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        (vim.hl or vim.highlight).on_yank()
    end,
})

-- Auto create dir when saving a file
vim.api.nvim_create_autocmd('BufWritePre', {
    callback = function(event)
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
    end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd('BufReadPost', {
    callback = function(event)
        -- local exclude = { 'gitcommit' } -- don't remember position in commit messages
        local mark = vim.api.nvim_buf_get_mark(event.buf, "'")
        local lcount = vim.api.nvim_buf_line_count(event.buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'text', 'markdown', 'gitcommit' },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
    pattern = {
        'help', 'lspinfo', 'checkhealth', 'qf', 'grug-far'
    },
    callback = function(event)
        vim.keymap.set('n', 'q', function()
            vim.cmd('close')
        end, { buffer = event.buf, silent = true, nowait = true })
    end,
})

-- Plugin related
-- vim.api.nvim_create_autocmd('PackChanged', {
--     callback = function(event)
--         if event.data.updated then
--             require('fff.download').download_or_build_binary()
--         end
--     end,
-- })

-- Images → zathura
vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = "*.pdf",
    callback = function()
        local filename = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
        vim.cmd("silent !zathura " .. filename .. " &")
        vim.cmd("let tobedeleted = bufnr('%') | b# | exe \"bd! \" . tobedeleted")
    end
})

-- Images → imv
vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = {
        "*.png",
        "*.jpg",
        "*.jpeg",
        "*.gif",
        "*.webp",
        "*.bmp",
        "*.tif",
        "*.tiff",
    },
    callback = function()
        local filename = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
        vim.cmd("silent !imv " .. filename .. " &")
        vim.cmd([[let tobedeleted = bufnr('%') | b# | exe "bd! " . tobedeleted]])
    end,
})

-- Videos → mpv
vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = {
        "*.mp4",
        "*.avi", -- video/x-msvideo
        "*.mkv", -- video/x-matroska
        "*.flv", -- video/x-flv
        "*.wmv", -- video/x-ms-wmv
        "*.mpeg", -- video/mpeg
        "*.mpg", -- often video/mpeg
        "*.ogv", -- video/ogg
        "*.webm", -- video/webm
        "*.mov", -- video/quicktime
        "*.3gp", -- video/3gpp
        "*.3g2", -- video/3gpp2
        "*.asf", -- video/x-ms-asf
        "*.ogm", -- video/x-ogm+ogg
    },
    callback = function()
        local filename = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
        vim.cmd("silent !mpv " .. filename .. " &")
        vim.cmd([[let tobedeleted = bufnr('%') | b# | exe "bd! " . tobedeleted]])
    end,
})

-- Auto-jump to first quickfix item, close the quickfix window, and notify
local group = vim.api.nvim_create_augroup("QfAutoJumpClose", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "qf",
    callback = function()
        -- Only act on the global quickfix list, not location lists
        if vim.fn.win_gettype(0) ~= "quickfix" then
            return
        end

        -- Defer so the window is fully created before we operate on it
        vim.schedule(function()
            local info = vim.fn.getqflist({ size = 1, items = 1, title = 1 })
            local size = info.size or 0

            if size > 0 then
                pcall(vim.cmd, "silent! cfirst") -- jump to the first entry
            end

            pcall(vim.cmd, "silent! cclose") -- close the quickfix window

            -- Build a helpful notification
            local title = info.title or "Quickfix"
            if size > 0 then
                local first = info.items and info.items[1] or nil
                local file, lnum, col, text = "", 1, 1, ""
                if first then
                    if first.bufnr and first.bufnr > 0 then
                        file = vim.api.nvim_buf_get_name(first.bufnr)
                    end
                    file = file ~= "" and file or (first.filename or "")
                    lnum = first.lnum or 1
                    col = first.col or 1
                    text = first.text or ""
                end
                vim.notify(
                    string.format("%s: %d items. Jumped to %s:%d:%d %s", title, size, file, lnum, col, text),
                    vim.log.levels.INFO,
                    { title = "Quickfix" }
                )
            else
                vim.notify(string.format("%s is empty. Closed the list.", title), vim.log.levels.INFO,
                    { title = "Quickfix" })
            end
        end)
    end,
})
