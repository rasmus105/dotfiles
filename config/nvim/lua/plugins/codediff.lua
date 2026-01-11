local map = vim.keymap.set

require("codediff").setup({
	-- Highlight configuration (using Gruvbox-friendly colors for better readability)
	highlights = {
		-- Line-level: accepts highlight group names or hex colors (e.g., "#2ea043")
		line_insert = "DiffAdd", -- Line-level insertions
		line_delete = "DiffDelete", -- Line-level deletions

		-- Character-level: explicit colors for better contrast with Gruvbox
		-- char_insert = "#b8bb26", -- Gruvbox bright green
		-- char_delete = "#fb4934", -- Gruvbox bright red
	},

	-- Diff view behavior
	diff = {
		disable_inlay_hints = true, -- Disable inlay hints in diff windows for cleaner view
		max_computation_time_ms = 5000, -- Maximum time for diff computation (VSCode default)
	},

	-- File explorer
	explorer = {
		view_mode = "tree",
	},

	-- Keymaps in diff view
	keymaps = {
		view = {
			quit = "q", -- Close diff tab
			toggle_explorer = "<leader>e", -- Toggle explorer visibility (explorer mode only)
			next_hunk = "]h", -- Jump to next change
			prev_hunk = "[h", -- Jump to previous change
			next_file = "]f", -- Next file in explorer mode
			prev_file = "[f", -- Previous file in explorer mode
		},
		explorer = {
			select = "<CR>", -- Open diff for selected file
			hover = "K", -- Show file diff preview
			refresh = "R", -- Refresh git status
		},
	},
})

-- Open diff explorer (git status)
map("n", "<leader>cd", ":CodeDiff<CR>", { desc = "Open diff explorer" })

-- Compare current file with HEAD
map("n", "<leader>cc", ":CodeDiff file HEAD<CR>", { desc = "Diff file with HEAD" })

-- Open merge mode for current file (for resolving conflicts)
map("n", "<leader>cm", function()
	vim.cmd("CodeDiff merge " .. vim.fn.expand("%"))
end, { desc = "Open merge tool for current file" })
