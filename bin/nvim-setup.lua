if arg[1] == "plugins" then
    dofile(vim.fn.stdpath("config") .. "/lua/config/vim-pack.lua")
    local drifted = {}
    local locked = {}
    for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
        if plugin.active then
            local head = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true }):wait()
            assert(head.code == 0, head.stderr)
            if vim.trim(head.stdout) ~= plugin.rev then
                drifted[#drifted + 1] = plugin.spec.name
                locked[plugin.spec.name] = plugin
            end
        end
    end
    if #drifted > 0 then
        vim.pack.update(drifted, { target = "lockfile", force = true })
        for _, plugin in pairs(locked) do
            local head = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true }):wait()
            assert(head.code == 0 and vim.trim(head.stdout) == plugin.rev,
                "Could not restore the locked revision of " .. plugin.spec.name)
        end
    end
    return
end

vim.g.dotfiles_setup = true
vim.cmd("LspSetup!")
vim.cmd.packadd("nvim-treesitter")

-- Replace the Zig parser if a stale revision cannot load the current queries.
local ok, query = pcall(vim.treesitter.query.get, "zig", "highlights")
if not ok or not query then
    assert(require("nvim-treesitter").install({ "zig" }, { force = true }):wait(300000),
        "Failed to install the Zig Tree-sitter parser")
end
