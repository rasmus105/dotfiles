local lsp_zero = require("lsp-zero")

--

lsp_zero.on_attach(function(client, bufnr)
	local opts = { buffer = bufnr, remap = false }

	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover()
	end, opts)
	vim.keymap.set("n", "<leader>vws", function()
		vim.lsp.buf.workspace_symbol()
	end, opts)
	vim.keymap.set("n", "<leader>vd", function()
		vim.diagnostic.open_float()
	end, opts)
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.goto_next()
	end, opts)
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.goto_prev()
	end, opts)
	vim.keymap.set("n", "<leader>vca", function()
		vim.lsp.buf.code_action()
	end, opts)
	vim.keymap.set("n", "<leader>vrr", function()
		vim.lsp.buf.references()
	end, opts)
	vim.keymap.set("n", "<leader>vrn", function()
		vim.lsp.buf.rename()
	end, opts)
	vim.keymap.set("i", "<C-h>", function()
		vim.lsp.buf.signature_help()
	end, opts)
end)

-- snippets keybindings

-- vim.keymap.set("n", "<Tab>", "<cmd>lua require('luasnip').jump(1)<Cr>")
-- vim.keymap.set("n", "<S-Tab>", "<cmd>lua require('luasnip').jump(-1)<Cr>")

--

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason").setup({
	ensure_installed = { "clang-format" },
})
require("mason-lspconfig").setup({
	ensure_installed = { "rust_analyzer", "clangd" },
	handlers = {
		lsp_zero.default_setup,
		-- local lspconfig = require('lspconfig'),
		lua_ls = function()
			local lua_opts = lsp_zero.nvim_lua_ls()
			require("lspconfig").lua_ls.setup(lua_opts)
		end,
		clangd = function()
			require("lspconfig").clangd.setup({
				capabilities = capabilities,
				-- Attempt to fix lsp errors with platformio espressif32 platform. Didn't work.
				-- cmd = {
				--     "clangd",
				--     "--background-index",
				--     "--query-driver=/home/rasmus105/.platformio/packages/toolchain-xtensa-esp32/bin/xtensa-esp32-elf-gcc*"
				-- },
			})
		end,
	},
})
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
	sources = {
		{ name = "path" },
		{ name = "nvim_lsp" },
		{ name = "nvim_lua" },
		{ name = "luasnip" },
	},
	formatting = lsp_zero.cmp_format(),
	mapping = cmp.mapping.preset.insert({
		["<Tab>"] = cmp.mapping.select_next_item(cmp_select),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<C-Space>"] = cmp.mapping.complete(),
	}),
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
})
vim.keymap.set({ "i", "s" }, "<C-L>", "<cmd>lua require('luasnip').jump(1)<CR>", { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", "<cmd>lua require('luasnip').jump(-1)<CR>", { silent = true })

--
-- imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
-- smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
-- imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
-- smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
