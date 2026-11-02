local map = vim.keymap.set
local buffer = vim.api.nvim_get_current_buf()
local group = vim.api.nvim_create_augroup("markdown_pdf", { clear = false })

local compiling = false
local pending = false
local pending_open = false

local function pdf_for(file)
    return vim.fn.fnamemodify(file, ":r") .. ".pdf"
end

local compile_current_file
compile_current_file = function(open_pdf)
    local file = vim.api.nvim_buf_get_name(buffer)
    if file == "" then
        vim.notify("Cannot compile an unnamed Markdown buffer", vim.log.levels.WARN)
        return
    end

    if compiling then
        pending = true
        pending_open = pending_open or open_pdf
        return
    end

    compiling = true
    local pdf = pdf_for(file)
    local directory = vim.fn.fnamemodify(file, ":h")

    vim.system({ "pandoc", file, "--pdf-engine=typst", "--output", pdf }, {
        cwd = directory,
        text = true,
    }, vim.schedule_wrap(function(result)
        compiling = false

        if not vim.api.nvim_buf_is_valid(buffer) then
            return
        end

        if result.code ~= 0 then
            local error = vim.trim(result.stderr or "")
            if error == "" then
                error = "pandoc exited with status " .. result.code
            end
            vim.notify("Markdown PDF conversion failed:\n" .. error, vim.log.levels.ERROR)
        elseif open_pdf then
            vim.ui.open(pdf)
        end

        if pending then
            local should_open = pending_open
            pending = false
            pending_open = false
            compile_current_file(should_open)
        end
    end))
end

local function watch_current_file()
    local file = vim.api.nvim_buf_get_name(buffer)
    if file == "" then
        vim.notify("Cannot watch an unnamed Markdown buffer", vim.log.levels.WARN)
        return
    end

    vim.api.nvim_clear_autocmds({ group = group, buffer = buffer })
    vim.cmd.update()
    compile_current_file(true)

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        buffer = buffer,
        callback = function()
            compile_current_file(false)
        end,
        desc = "Rebuild Markdown PDF",
    })
end

vim.api.nvim_clear_autocmds({ group = group, buffer = buffer })
map({ "n", "x" }, "<leader>m", watch_current_file, { buffer = true, desc = "markdown PDF watch" })
