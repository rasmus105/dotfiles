return {
	{ -- TODO CHECK
		enabled = false,
		"folke/flash.nvim",
		opts = {
			search = {
				forward = true,
				multi_window = false,
				wrap = false,
				incremental = true,
			},
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
			"nvim-telescope/telescope-file-browser.nvim",
		},
		keys = function()
			return {
				{
					-- ";f",
					"\\f",
					function()
						require("telescope.builtin").find_files()
					end,
					desc = "Find Files",
				},
				{
					";a",
					function()
						require("telescope.builtin").find_files({
							no_ignore = false,
							hidden = true,
						})
					end,
					desc = "Find all files",
				},
				{
					-- ";w",
					"\\w",
					function()
						require("telescope.builtin").live_grep({
							additional_args = { "--hidden" },
						})
					end,
					desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
				},
				{
					-- ";b",
					"\\b",
					function()
						require("telescope.builtin").buffers()
					end,
					desc = "Lists open buffers",
				},
				{
					-- ";t",
					"\\t",
					function()
						require("telescope.builtin").help_tags()
					end,
					desc = "Lists available help tags and opens a new window with the relevant help info on <cr>",
				},
				{
					-- ";e",
					"\\e",
					function()
						require("telescope.builtin").diagnostics()
					end,
					desc = "Lists Diagnostics for all open buffers or a specific buffer",
				},
				{
					-- ";s",
					"\\s",
					function()
						require("telescope.builtin").treesitter()
					end,
					desc = "Lists Function names, variables, from Treesitter",
				},
				{ -- file browser
					-- ";h",
					"\\h",
					function()
						local telescope = require("telescope")

						local function telescope_buffer_dir()
							return vim.fn.expand("%:p:h")
						end

						telescope.extensions.file_browser.file_browser({
							path = "%:p:h",
							cwd = telescope_buffer_dir(),
							respect_gitignore = false,
							hidden = true,
							grouped = true,
							previewer = false,
							initial_mode = "normal",
							layout_config = { height = 40 },
						})
					end,
					desc = "Open File Browser with the path of the current buffer",
				},
			}
		end,
		config = function(_, opts)
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local fb_actions = require("telescope").extensions.file_browser.actions

			opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
				wrap_results = true,
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "bottom" },
				sorting_strategy = "descending",
				winblend = 0,
				mappings = {
					n = {},
				},
			})
			opts.pickers = {
				diagnostics = {
					theme = "ivy",
					initial_mode = "normal",
					layout_config = {
						preview_cutoff = 9999,
					},
				},
			}
			opts.extensions = {
				file_browser = {
					theme = "dropdown",
					-- disables netrw and use telescope-file-browser in its place
					hijack_netrw = true,
					mappings = {
						-- your custom insert mode mappings
						["n"] = {
							-- your custom normal mode mappings
							["N"] = fb_actions.create,
							["h"] = fb_actions.goto_parent_dir,
							["/"] = function()
								vim.cmd("startinsert")
							end,
							["<C-u>"] = function(prompt_bufnr)
								for i = 1, 10 do
									actions.move_selection_previous(prompt_bufnr)
								end
							end,
							["<C-d>"] = function(prompt_bufnr)
								for i = 1, 10 do
									actions.move_selection_next(prompt_bufnr)
								end
							end,
							["<PageUp>"] = actions.preview_scrolling_up,
							["<PageDown>"] = actions.preview_scrolling_down,
						},
					},
				},
			}
			telescope.setup(opts)
			require("telescope").load_extension("fzf")
			require("telescope").load_extension("file_browser")
		end,
	},

	{ -- TODO CHECK
		"kazhala/close-buffers.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<leader>th",
				function()
					require("close_buffers").delete({ type = "hidden" })
				end,
				"Close Hidden Buffers",
			},
			{
				"<leader>tu",
				function()
					require("close_buffers").delete({ type = "nameless" })
				end,
				"Close Nameless Buffers",
			},
		},
	},

	{
		"saghen/blink.cmp",
		opts = {
			signature = {
				window = {
					winblend = vim.o.pumblend,
				},
			},
			--[[ default = { "lsp", "path", "snippets", "buffer", "luasnip" },
            providers = {
                lsp = "lsp",
                enabled = true
                module = "blink.cmp.sources.lsp",
                kind = "LSP",
                score_offset = 1000, -- higher number -> higher priority
            },
            luasnip = {
                name = "luasnip",
                enabled = true,
                module = "blink.cmp.sources.luasnip",
                score_offset = 950,
            },]]
		},
	},
}
