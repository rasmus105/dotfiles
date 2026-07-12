local lazy = require("config.lazy")

local codediff_config = {
	highlights = {
		line_insert = "DiffAdd", -- Line-level insertions
		line_delete = "DiffDelete", -- Line-level deletions
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
			focus_explorer = "<leader>b", -- default overlaps with above keymap
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
}

local load_codediff = lazy.once("codediff", function()
	lazy.packadd("codediff.nvim")
	lazy.del_user_command("VscodeDiff")

	-- Apply config without requiring codediff.ui, which loads the heavy diff UI stack.
	require("codediff.config").setup(codediff_config)
	require("codediff.ui.highlights").setup()
end)

lazy.on_cmd("CodeDiff", load_codediff)

-- When codediff is opened in a standalone session, quit neovim after closing the diff.
vim.api.nvim_create_user_command("CodeDiffStandalone", function(opts)
	local group = vim.api.nvim_create_augroup("CodeDiffStandalone", { clear = true })
	vim.g.codediff_standalone = true

	vim.api.nvim_create_autocmd("TabClosed", {
		group = group,
		callback = function()
			vim.schedule(function()
				if vim.g.codediff_standalone and vim.fn.tabpagenr("$") == 1 then
					vim.g.codediff_standalone = false
					vim.cmd("qa")
				end
			end)
		end,
	})

	load_codediff()
	vim.api.nvim_cmd({ cmd = "CodeDiff", args = opts.fargs }, {})
end, { nargs = "*", desc = "Open CodeDiff as a standalone session" })
