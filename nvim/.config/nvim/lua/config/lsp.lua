require('mason').setup()
require('mason-lspconfig').setup()

require('mason-tool-installer').setup({
	ensure_installed = {
		"rust_analyzer", -- Rust language server
		"clangd", -- C/C++ language server
		"lua_ls", -- Lua language server
		"ts_ls", -- Typescript language server
		"pyright", -- Python language server
		"zls", -- Zig language server

		"rustfmt", -- Rust formatter
		"clang-format", -- C/C++ formatter
		"stylua", -- Lua formatter
		"black", -- Python formatter
	}
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

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP actions",
	callback = function(event)
		-- local opts = { buffer = event.buf, noremap = true, silent = true }
		local opts = { buffer = event.buf }

		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- Show information
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) --
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts) --
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts) --
		-- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts) -- show window with references

		-- Show referneces in telescope prompt (SWITCHED TO USING SNACKS PICKER INSTEAD!)
		-- vim.keymap.set("n", "gr", function()
		-- 	require("telescope.builtin").lsp_references({
		-- 		include_declaration = false, -- Set to true if you want to include declarations
		-- 		show_line = true,
		-- 	})
		-- end, opts)

		vim.keymap.set("n", "<leader>cs", vim.lsp.buf.signature_help, opts) --
		-- vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, opts) -- Rename
		-- Raname while showing all changes
		vim.keymap.set("n", "<leader>cr", function()
			-- return ":IncRename " .. vim.fn.expand("<cword>") -- Start with old name
			return ":IncRename " -- Start with empty name
		end, { expr = true })
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- code action
		vim.keymap.set("n", "<leader>ch", ":ClangdSwitchSourceHeader<CR>") -- code action
	end,
})
