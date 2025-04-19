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
}
