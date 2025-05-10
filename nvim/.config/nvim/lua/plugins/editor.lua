return {
	{ -- Menu for seeing keybindings
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({
				delay = 500,
			})
		end,
	},

	{ -- Plugin for quickly deleting buffers.
		"kazhala/close-buffers.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<leader>bh",
				function()
					vim.cmd("wall") -- Save before closing buffers
					require("close_buffers").delete({ type = "hidden" }) --
				end,
				desc = "Save All & Close Hidden Buffers",
			},
			{
				"<leader>bu",
				function()
					require("close_buffers").delete({ type = "nameless" })
				end,
				desc = "Close Nameless Buffers",
			},
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		enabled = true,

		opts = {},
	},

	{
		"akinsho/toggleterm.nvim",
		version = "*",

		config = true,
	},

	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },

		config = function()
			local harpoon = require("harpoon")

			harpoon:setup({
				settings = {
					save_on_toggle = true,
					sync_on_ui_close = true,
				},
			})

			harpoon:extend(require("harpoon.extensions").builtins.highlight_current_file())

			-- Override the default menu UI to add number key mappings
			local orig_ui_toggle = harpoon.ui.toggle_quick_menu
			harpoon.ui.toggle_quick_menu = function(...)
				orig_ui_toggle(...)

				-- Get the harpoon window/buffer if it exists
				local win = vim.api.nvim_get_current_win()
				local buf = vim.api.nvim_win_get_buf(win)
				local bufname = vim.api.nvim_buf_get_name(buf)

				-- Check if this is the harpoon menu
				if bufname:match("harpoon") then
					-- Map 1-9 keys in the harpoon buffer
					for i = 1, 9 do
						vim.api.nvim_buf_set_keymap(
							buf,
							"n",
							tostring(i),
							":lua require('harpoon'):list():select(" .. i .. ")<CR>",
							{ noremap = true, silent = true }
						)
					end
				end
			end
		end,
		keys = function()
			local keys = {
				{
					"<leader>a",
					function()
						require("harpoon"):list():add()
					end,
					desc = "harpoon file",
				},
				{
					"<S-h>",
					function()
						local harpoon = require("harpoon")
						harpoon.ui:toggle_quick_menu(harpoon:list())
					end,
					desc = "harpoon quick menu",
				},
			}

			-- create keymap for <leader>[number] to jump to a file in the harpoon list.
			for i = 1, 9 do
				table.insert(keys, {
					"<leader>" .. i,
					function()
						require("harpoon"):list():select(i)
					end,
					desc = "harpoon to file " .. i,
				})
			end
			return keys
		end,
	},

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		build = ":Copilot auth",
		config = function()
			require("copilot").setup({
				log_level = vim.log.levels.DEBUG,
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<C-J>",
					},
				},
				panel = { enabled = false },
			})
		end,
	},

	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = {
			{ "<leader>al", "<cmd>CodeCompanion<CR>", desc = "Inline" },
			{ "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", desc = "Chat" },
			{ "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "Actions" },
			{
				"<leader>at",
				'<cmd>lua require("copilot.suggestion").toggle_auto_trigger()<CR>',
				desc = "Toggle Inline",
			},
		},
		opts = {
			opts = {
				log_level = "DEBUG",
			},
			display = {
				chat = {
					show_settings = true,
					retain_context = false, -- keep the context of the conversation
				},
			},
			strategies = {
				chat = {
					adapter = "copilot",
					keymaps = {
						completion = {
							modes = {
								i = "<C-J>",
							},
							index = 1,
							callback = "keymaps.completion",
							description = "Completion Menu",
						},
					},
				},
				slash_commands = {
					["buffer"] = {
						callback = "strategies.chat.slash_commands.buffer",
						description = "Insert open buffers",
						opts = {
							contains_code = true,
							provider = "telescope", -- default|telescope|mini_pick|fzf_lua
						},
					},
					["fetch"] = {
						callback = "strategies.chat.slash_commands.fetch",
						description = "Insert URL contents",
						opts = {
							adapter = "jina",
						},
					},
					["file"] = {
						callback = "strategies.chat.slash_commands.file",
						description = "Insert a file",
						opts = {
							contains_code = true,
							max_lines = 1000,
							provider = "telescope", -- default|telescope|mini_pick|fzf_lua
						},
					},
					["files"] = {
						callback = "strategies.chat.slash_commands.files",
						description = "Insert multiple files",
						opts = {
							contains_code = true,
							max_lines = 1000,
							provider = "telescope", -- default|telescope|mini_pick|fzf_lua
						},
					},
					["help"] = {
						callback = "strategies.chat.slash_commands.help",
						description = "Insert content from help tags",
						opts = {
							contains_code = false,
							provider = "telescope", -- telescope|mini_pick|fzf_lua
						},
					},
					["now"] = {
						callback = "strategies.chat.slash_commands.now",
						description = "Insert the current date and time",
						opts = {
							contains_code = false,
						},
					},
					["symbols"] = {
						callback = "strategies.chat.slash_commands.symbols",
						description = "Insert symbols for a selected file",
						opts = {
							contains_code = true,
							provider = "telescope", -- default|telescope|mini_pick|fzf_lua
						},
					},
					["terminal"] = {
						callback = "strategies.chat.slash_commands.terminal",
						description = "Insert terminal output",
						opts = {
							contains_code = false,
						},
					},
				},
				inline = {
					adapter = "copilot",
				},
				agent = {
					adapter = "copilot",
				},
			},
			adapters = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							model = {
								default = "claude-3.5-sonnet",
							},
						},
					})
				end,
			},
		},
	},
}
