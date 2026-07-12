local map = vim.keymap.set
local lazy = require("config.lazy")

-- Global auto-format toggle
vim.g.autoformat = true

local function toggle_autoformat()
    vim.g.autoformat = not vim.g.autoformat
    local status = vim.g.autoformat and "enabled" or "disabled"
    print("Auto-formatting " .. status)
end

for _, key in ipairs({ "grr", "grn", "gra", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, "n", key)
end

-- LSP Keymaps (apply to all LSP servers)
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        local opts = { buffer = ev.buf, nowait = true }
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        if client and client.name == "tinymist" then
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].filetype == "typst" then
                    vim.bo[ev.buf].formatexpr = ""
                end
            end)
        end

        -- Toggle keymaps
        map("n", "<leader>te", function()
            vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end, { buffer = ev.buf, desc = "Toggle Diagnostics" })
        map("n", "<leader>tf", toggle_autoformat, { buffer = ev.buf, desc = "Toggle auto-format" })

        -- Navigation
        map("n", "K", vim.lsp.buf.hover, opts)
        map("n", "gk", vim.lsp.buf.signature_help, opts)
        map("n", "gD", vim.lsp.buf.declaration, opts)
        map("n", "gi", vim.lsp.buf.implementation, opts)
        -- map('n', 'gd', vim.lsp.buf.definition, opts) -- using fzf-lua for this
        -- map('n', 'gr', vim.lsp.buf.references, opts) -- using fzf-lua for this

        -- Code actions
        map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        map("n", "<leader>cr", vim.lsp.buf.rename, opts)
        if client and client.name == "zls" then
            map("n", "<leader>cf", function()
                vim.lsp.buf.code_action({
                    context = { only = { "source.fixAll" } },
                    apply = true,
                })
            end, { buffer = ev.buf, desc = "ZLS fix all" })
        end
        map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, opts)

        -- Diagnostics
        map("n", "<leader>ch", ":LspClangdSwitchSourceHeader<CR>") -- code action
        map("n", "gl", vim.diagnostic.open_float, { buffer = ev.buf, desc = "Show diagnostic as float" })

        -- Format on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = ev.buf,
            callback = function(args)
                local clients = vim.lsp.get_clients({
                    bufnr = args.buf,
                    method = "textDocument/formatting",
                })

                if #clients == 0 then
                    return
                end

                vim.lsp.buf.format({
                    bufnr = args.buf,
                    timeout_ms = 1000,
                })
            end,
        })
    end,
})

local setup_lsp = lazy.once("lsp", function()
    lazy.packadd("nvim-lspconfig")
    lazy.packadd("mason.nvim")
    lazy.packadd("mason-lspconfig.nvim")
    lazy.packadd("mason-tool-installer.nvim")

    require("mason").setup()
    require("mason-lspconfig").setup({
        automatic_enable = {
            exclude = {
                "julials", -- Mason's julials config adds the env arg too late for this Neovim build.
                -- using neovim plugin to extend rust LSP capabilities, and it will
                -- handle starting rust analyzer.
                "rust_analyzer",
            },
        },
    })
    vim.lsp.enable("julials")

    require("mason-tool-installer").setup({
        ensure_installed = {
            "clangd", -- C/C++ language server
            "julials", -- Julia language server
            "lua_ls", -- Lua language server
            -- "emmylua_ls", -- Another lua language server
            "zls", -- Zig language server
            "tinymist", -- Typst language server
            "marksman", -- Markdown language server
            "codelldb", -- Debug adapter for Zig/C/C++/Rust
            "clang-format", -- C/C++ formatter
            "stylua", -- Lua formatter
            "shellcheck", -- Shell linter
            "shfmt", -- Shell formatter
        },
    })

    require("plugins.luasnip").setup()
    lazy.packadd("blink.cmp")

    -- Autocompletion
    require("blink.cmp").setup({
        fuzzy = { implementation = "prefer_rust_with_warning" },
        -- build = 'cargo build --release',
        signature = { enabled = true },
        snippets = { preset = "luasnip" },
        keymap = {
            preset = "default",
            --
            ["<Tab>"] = { "fallback" },
            ["<S-Tab>"] = { "fallback" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-l>"] = { "snippet_forward", "fallback" },
            ["<C-h>"] = { "snippet_backward", "fallback" },
            ["<C-g>"] = { "accept", "fallback" },
            ["<C-c>"] = { "cancel", "fallback" },
            -- unbind keybindings that interfer with other keybindings
            ["<C-e>"] = false,
            ["<C-a>"] = false,
            ["<C-f>"] = false,
            ["<C-b>"] = false,
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        },
        appearance = {
            use_nvim_cmp_as_default = false,
            nerd_font_variant = "mono",
        },
        completion = {
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 0,
                window = {
                    border = "none",
                },
            },
        },
        sources = { default = { "lsp", "snippets" } },
        cmdline = {
            enabled = true,
            completion = { menu = { auto_show = false } },
            keymap = {
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" },
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-g>"] = { "accept", "fallback" },
                ["<C-c>"] = { "cancel", "fallback" },
                -- unbind keybindings that interfer with other keybindings
                ["<C-e>"] = false,
                ["<C-a>"] = false,
                ["<C-f>"] = false,
                ["<C-b>"] = false,
                ["<C-Space>"] = { "show", "fallback" },
            },
        },
    })

    vim.schedule(function()
        if next(vim.lsp._enabled_configs) then
            vim.cmd.doautoall("nvim.lsp.enable FileType")
        end
    end)
end)

lazy.on_event({ "BufReadPost", "BufNewFile" }, "Lsp", setup_lsp, { once = true, schedule = true })
lazy.on_event({ "InsertEnter", "CmdlineEnter" }, "LspImmediate", setup_lsp, { once = true })

vim.api.nvim_create_user_command("LspSetup", setup_lsp, { desc = "Load LSP and completion plugins" })
