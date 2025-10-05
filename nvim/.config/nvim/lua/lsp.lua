local map = vim.keymap.set

require("nvim-treesitter.configs").setup({
    ensure_installed = { "c", "zig", "rust", "lua", "javascript" },
    sync_install = false,
    auto_install = true,
    ignore_install = {},
    modules = {},
    highlight = {
        enable = true,
        disable = function(lang, buf)
            local max_filesize = 1000 * 1024 -- 1 MB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,

    },
})
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


-- LSP Keymaps (apply to all LSP servers)
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        local opts = { buffer = ev.buf }

        -- Navigation
        map('n', 'K', vim.lsp.buf.hover, opts)
        map('n', 'gk', vim.lsp.buf.signature_help, opts)
        -- map('n', 'gd', vim.lsp.buf.definition, opts)
        map('n', 'gD', vim.lsp.buf.declaration, opts)
        -- map('n', 'gr', vim.lsp.buf.references, opts) -- using fzf-lua for this
        map('n', 'gi', vim.lsp.buf.implementation, opts)
        map('n', '<S-k>', vim.lsp.buf.signature_help, opts)
        -- map('n', '<S-k>', vim.lsp.buf.information??

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

-- Autocompletion
require('blink.cmp').setup({
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    -- build = 'cargo build --release',
    signature = { enabled = true },
    keymap = {
        preset = "default",
        ["<C-Tab>"] = { "select_prev", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },

        ["<C-l>"] = { "snippet_forward", "fallback" },
        ["<C-h>"] = { "snippet_backward", "fallback" },

        ["<C-Enter>"] = { "accept", "fallback" },

        ["<C-b>"] = { "scroll_documentation_down", "fallback" },
        ["<C-f>"] = { "scroll_documentation_up", "fallback" },
        ["<C-y>"] = { "show", "show_documentation", "hide_documentation" },
    },

    appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "normal",
    },

    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
        }
    },

    sources = { default = { "lsp" } }
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

vim.lsp.config('zls', {
    settings = {
        enable_build_on_save = true,
    }
})
