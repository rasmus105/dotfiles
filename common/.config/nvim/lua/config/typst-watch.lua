local M = {}
local watchers = {}

local function current_file()
    local file = vim.api.nvim_buf_get_name(0)
    return vim.uv.fs_realpath(file) or file
end

local function stop_watcher(file)
    local watcher = watchers[file]
    if not watcher then
        return
    end

    watchers[file] = nil
    if watcher.job and vim.fn.jobwait({ watcher.job }, 0)[1] == -1 then
        vim.fn.jobstop(watcher.job)
    end
    if vim.api.nvim_buf_is_valid(watcher.log) then
        vim.api.nvim_buf_delete(watcher.log, { force = true })
    end
end

function M.watch()
    local file = current_file()
    local buffer = vim.api.nvim_get_current_buf()
    local watcher = watchers[file]
    if watcher and vim.fn.jobwait({ watcher.job }, 0)[1] == -1 then
        watcher.buffers[buffer] = true
        return
    end

    if vim.fn.executable("typst") ~= 1 then
        vim.notify("Cannot watch this document: typst is not installed", vim.log.levels.ERROR)
        return
    end

    stop_watcher(file)
    watcher = {
        buffers = { [buffer] = true },
        log = vim.api.nvim_create_buf(false, true),
        pdf = vim.fn.fnamemodify(file, ":r") .. ".pdf",
    }
    watchers[file] = watcher
    vim.bo[watcher.log].bufhidden = "hide"

    local pending = ""
    -- Keep the terminal output available without creating a window or tab.
    watcher.job = vim.api.nvim_buf_call(watcher.log, function()
        return vim.fn.jobstart({ "typst", "watch", file, watcher.pdf, "--diagnostic-format=short" }, {
            term = true,
            on_stdout = function(_, data)
                if watchers[file] ~= watcher then
                    return
                end
                pending = pending .. table.concat(data, "\n")
                while pending:find("\n", 1, true) do
                    local line, rest = pending:match("^(.-)\n(.*)$")
                    pending = rest
                    line = line:gsub("\27%[[%d;]*[A-Za-z]", ""):gsub("\r", "")
                    if line:find("error:", 1, true) then
                        vim.notify("Typst: " .. line, vim.log.levels.ERROR)
                    end
                end
            end,
            on_exit = function(_, code)
                if watchers[file] == watcher and vim.v.exiting == vim.NIL then
                    vim.notify(
                        "Typst watcher stopped (status "
                            .. code
                            .. "); see :TypstWatchLog or press <leader>m to restart",
                        vim.log.levels.WARN
                    )
                end
            end,
        })
    end)

    if watcher.job <= 0 then
        stop_watcher(file)
        vim.notify("Could not start the Typst watcher", vim.log.levels.ERROR)
        return
    end

    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = watcher.log, silent = true, desc = "Close watcher output" })
end

function M.show_log()
    local watcher = watchers[current_file()]
    if not watcher or not vim.api.nvim_buf_is_valid(watcher.log) then
        vim.notify("No Typst watcher for this document", vim.log.levels.INFO)
        return
    end

    local window = vim.fn.bufwinid(watcher.log)
    if window ~= -1 then
        vim.api.nvim_set_current_win(window)
    else
        vim.cmd("botright 12split")
        vim.api.nvim_win_set_buf(0, watcher.log)
    end
end

function M.stop()
    stop_watcher(current_file())
end

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "BufFilePre" }, {
    group = vim.api.nvim_create_augroup("typst_watch", { clear = true }),
    callback = function(event)
        for file, watcher in pairs(watchers) do
            watcher.buffers[event.buf] = nil
            if not next(watcher.buffers) then
                stop_watcher(file)
            end
        end
    end,
    desc = "Stop Typst watchers when their document buffers are removed or renamed",
})

return M
