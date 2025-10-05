local map = vim.keymap.set

require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup({
    ensure_installed = {
        "rust_analyzer", -- Rust language server
        "clangd",        -- C/C++ language server
        "lua_ls",        -- Lua language server
        "ts_ls",         -- Typescript language server
        "pyright",       -- Python language server
        "zls",           -- Zig language server

        "rustfmt",       -- Rust formatter
        "clang-format",  -- C/C++ formatter
        "stylua",        -- Lua formatter
        "black",         -- Python formatter
    }
})

map("n", "<leader>te", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end)

-- LSP Keymaps (apply to all LSP servers)
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        local opts = { buffer = ev.buf }

        -- Navigation
        map('n', 'K', vim.lsp.buf.hover, opts)
        map('n', 'gd', vim.lsp.buf.definition, opts)
        map('n', 'gD', vim.lsp.buf.declaration, opts)
        map('n', 'gr', vim.lsp.buf.references, opts)
        map('n', 'gi', vim.lsp.buf.implementation, opts)
        map('n', '<C-k>', vim.lsp.buf.signature_help, opts)

        -- Code actions
        map('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        map('n', '<leader>rn', vim.lsp.buf.rename, opts)
        map('n', '<leader>f', function()
            vim.lsp.buf.format { async = true }
        end, opts)

        -- Diagnostics
        map('n', '[d', vim.diagnostic.get_prev, opts)
        map('n', ']d', vim.diagnostic.get_next, opts)
        map('n', '<leader>q', vim.diagnostic.setloclist, opts)
        map("n", "<leader>ch", ":ClangdSwitchSourceHeader<CR>") -- code action
        map("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostic as float" })
    end,
})

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
            diagnostics = {
                globals = {
                    'vim',
                    'require'
                },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})
