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
}
