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

local treesitter = require("nvim-treesitter")
local parsers = {
    "bash", "c", "cmake", "cpp", "css", "diff", "dockerfile", "dtd",
    "editorconfig", "fish", "git_config", "git_rebase", "gitattributes", "gitignore",
    "go", "gomod", "gosum", "gotmpl", "gowork", "graphql", "html", "ini",
    "java", "javascript", "jsdoc", "json", "json5", "julia", "just", "kotlin",
    "lua", "luadoc", "make", "markdown", "markdown_inline", "meson", "ninja", "nix",
    "php", "php_only", "proto", "python", "requirements", "ruby", "rust", "scss",
    "ssh_config", "svelte", "swift", "terraform", "toml", "tsx", "typescript",
    "typst", "vim", "vimdoc", "vue", "xml", "yaml", "zig",
}

-- A failed install can leave queries behind even when the parser is missing.
local installed = treesitter.get_installed("parsers")
local missing = vim.tbl_filter(function(parser)
    return not vim.list_contains(installed, parser)
end, parsers)
assert(treesitter.install(missing, { force = true, summary = true }):wait(300000),
    "Failed to install Tree-sitter parsers")
assert(treesitter.update(parsers, { summary = true }):wait(300000),
    "Failed to update Tree-sitter parsers")

installed = treesitter.get_installed("parsers")
for _, parser in ipairs(parsers) do
    assert(vim.list_contains(installed, parser), "Tree-sitter parser is missing: " .. parser)
end
