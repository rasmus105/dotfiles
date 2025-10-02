return {
	{ -- Managing LSPs, DAPs, linters, & formatters
		"williamboman/mason.nvim",
		opts = {
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

				-- Not sure about below
				-- "stylua",
				-- "selene",
				-- "luacheck",
				-- "shellcheck",
				-- "shfmt",
			},
		},
	},

	{ -- Allows easier integration with neovim-lspconfig
		"williamboman/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"rust_analyzer", -- Rust language server
				"clangd", -- C/C++ language server
				"lua_ls", -- Lua language server
				"ts_ls", -- Typescript language server
			},
		},
	},

	{ -- Snippets engine
		"L3MON4D3/LuaSnip",
		dependencies = {
			"rafamadriz/friendly-snippets", -- Bunch of useful snippets
		},
		lazy = true,
		priority = 950,
		opts = {},
	},

	{ -- Autocompletion plugin
		"saghen/blink.cmp",

		version = "*",
		build = "...",

		enabled = true,

		dependencies = {
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets",
		},

		opts = function(_, opts)
			-- Problems with telescope performance when using blink.cmp, so disabling it for telescope.
			opts.enabled = function()
				local filetype = vim.bo[0].filetype
				if filetype == "TelescopePrompt" or filetype == "minifiles" or filetype == "snacks_picker_input" then
					return false
				end
				return true
			end

			opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					lsp = {
						name = "lsp",
						enabled = true,
						module = "blink.cmp.sources.lsp",
						-- kind = "LSP",

						score_offset = 90, -- The higher the number, the higher the priority
					},
					path = {
						name = "Path",
						module = "blink.cmp.sources.path",
						score_offset = 25,

						fallbacks = { "snippets", "buffer" }, -- only show snippets if no paths are available

						opts = {
							trailing_slash = false,
							label_trailing_slash = true,
							get_cwd = function(context)
								return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
							end,
							show_hidden_files_by_default = true,
						},
					},
					buffer = {
						name = "Buffer",
						enabled = true,
						max_items = 3,
						module = "blink.cmp.sources.buffer",
						score_offset = 15, -- the higher the number, the higher the priority
					},
					snippets = {
						name = "snippets",
						enabled = true,
						max_items = 10,

						module = "blink.cmp.sources.snippets",
						score_offset = 20,
					},
				},
			})

			-- opts.fuzzy = {
			--     implementation = "prefer_rust_with_warning",
			-- }

			opts.snippets = {
				preset = "luasnip",
			}

			-- This is temporary, until tmux implements `Kitty key protocol`, so
			-- that it will recognize `Ctrl+Enter`.
			local in_alacritty = vim.env.TERM == "alacritty"
			local autocomplete_keybind = in_alacritty and "<C-y>" or "<C-Enter>"

			-- https://cmp.saghen.dev/configuration/keymap.html
			opts.keymap = {
				preset = "default",

				["<Tab>"] = { "select_next", "fallback" },
				["<C-Tab>"] = { "select_prev", "fallback" },

				-- ["<C-Enter>"] = { "accept", "fallback" },
				[autocomplete_keybind] = { "accept", "fallback" },

				["<C-l>"] = { "snippet_forward", "fallback" },
				["<C-h>"] = { "snippet_backward", "fallback" },
			}

			return opts
		end,
	},

	{ -- LSP
		"neovim/nvim-lspconfig",

		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			-- 'saghen/blink.cmp'
		},

		keys = {
			{
				"<leader>te",
				function()
					vim.diagnostic.enable(not vim.diagnostic.is_enabled())
				end,
				desc = "Toggle Diagnostics",
			},
		},

		config = function()
			local lspconfig = require("lspconfig")
			local lspconfig_defaults = lspconfig.util.default_config
			lspconfig_defaults.capabilities = vim.tbl_deep_extend(
				"force",
				lspconfig_defaults.capabilities,
				require("blink.cmp").get_lsp_capabilities()
			)

			-- lspconfig.rust_analyzer.setup({}) -- using seperate plugin now, so this is commented out.
			lspconfig.clangd.setup({
				cmd = {
					"clangd",
					"--query-driver=/home/rk105/programming/toolchains/arm-gnu-toolchain-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc",
				},
			})
			lspconfig.lua_ls.setup({})
			lspconfig.ts_ls.setup({})
			lspconfig.pyright.setup({})
			lspconfig.zls.setup({})

			-- Setup keymaps for LSP functionality
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
		end,
	},

	{ -- Formatting plugin
		"stevearc/conform.nvim",
		enabled = true,

		opts = {
			formatters_by_ft = { -- If a specific formatter is wanted, put it here
				lua = { "stylua" },
				rust = { "rustfmt" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				arduino = { "clang_format" },
			},
			formatters = {
				c_formatter = {
					command = "clang-format",
					args = '--style="{BasedOnStyle: LLVM, UseTab: Always, IndentWidth: 4, TabWidth: 4, AlignConsecutiveMacros: true}"',
				},
				clang_format = {
					command = "clang-format",
					prepend_args = {
						"--style=file",
						"--fallback-style=LLVM",
					},
				},
			},
			format_on_save = function(bufnr)
				-- Allow for toggling format on save
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		},
	},

	{ -- Fancy features for rust
		"mrcjkb/rustaceanvim",
		version = "^6", -- Recommended
		lazy = false, -- This plugin is already lazy
	},
}
