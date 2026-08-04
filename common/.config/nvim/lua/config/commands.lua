vim.api.nvim_create_user_command("T", function(opts)
    vim.cmd("tabnew")
    local terminal_buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_create_autocmd("TermClose", {
        buffer = terminal_buf,
        once = true,
        callback = function(args)
            if vim.api.nvim_buf_is_valid(args.buf) then
                vim.bo[args.buf].modified = false
            end
        end,
    })

    vim.cmd("terminal " .. opts.args)

    vim.bo.bufhidden = "wipe"
    vim.bo.buflisted = false

    vim.keymap.set("n", "q", function()
        if #vim.api.nvim_list_tabpages() > 1 then
            vim.cmd("tabclose!")
            return
        end

        vim.api.nvim_buf_delete(terminal_buf, { force = true })
        vim.cmd("quit")
    end, {
        buffer = true,
        silent = true,
        nowait = true,
        desc = "Close terminal tab",
    })
end, {
    nargs = "+",
    complete = "shellcmd",
})

vim.api.nvim_create_user_command("PackClean", function()
    local active_plugins = {}
    local unused_plugins = {}

    for _, plugin in ipairs(vim.pack.get()) do
        active_plugins[plugin.spec.name] = plugin.active
    end

    for _, plugin in ipairs(vim.pack.get()) do
        if not active_plugins[plugin.spec.name] then
            table.insert(unused_plugins, plugin.spec.name)
        end
    end

    if #unused_plugins == 0 then
        print("No unused plugins.")
        return
    end

    local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
    if choice == 1 then
        vim.pack.del(unused_plugins)
    end
end, {})
