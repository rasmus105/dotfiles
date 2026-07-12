local map = vim.keymap.set

local function pdf_for(file)
    return vim.fn.fnamemodify(file, ":r") .. ".pdf"
end

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

    local pdf = pdf_for(file)
    local result = vim.system({ "typst", "compile", file }):wait()
    if result.code ~= 0 then
        vim.notify("Typst compile failed:\n" .. result.stderr, vim.log.levels.ERROR)
        return
    end

    vim.ui.open(pdf)
    local script = vim.fn.shellescape('typst watch "$1"; exec bash')
    vim.cmd("T bash -c " .. script .. " _ " .. vim.fn.shellescape(file))
end

map({ "n", "v", "x" }, "<leader>m", watch_current_file, { buffer = true, desc = "typst watch" })
