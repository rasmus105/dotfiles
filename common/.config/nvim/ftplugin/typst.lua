local map = vim.keymap.set

local function compile_current_file()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
        vim.notify("Cannot compile an unnamed Typst buffer", vim.log.levels.WARN)
        return
    end

    vim.cmd.update()
    vim.cmd("T typst compile " .. vim.fn.shellescape(file))
end

vim.api.nvim_buf_create_user_command(0, "TypstCompile", compile_current_file, {
    desc = "Compile current Typst file",
})

local function watch_current_file()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
        vim.notify("Cannot watch an unnamed Typst buffer", vim.log.levels.WARN)
        return
    end

    vim.cmd.update()

    require("config.typst-watch").watch()
end

vim.api.nvim_buf_create_user_command(0, "TypstWatchLog", function()
    require("config.typst-watch").show_log()
end, { desc = "Show Typst watcher output" })

vim.api.nvim_buf_create_user_command(0, "TypstWatchStop", function()
    require("config.typst-watch").stop()
end, { desc = "Stop watching the current Typst document" })

map({ "n", "x" }, "<leader>m", watch_current_file, { buffer = true, desc = "typst PDF watch" })
