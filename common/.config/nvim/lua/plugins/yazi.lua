local lazy = require("config.lazy")

local setup = lazy.once("yazi", function()
	lazy.packadd("plenary.nvim")
	lazy.packadd("yazi.nvim")
	require("yazi").setup({
		floating_window_scaling_factor = 1,
		yazi_floating_window_zindex = 1,
		yazi_floating_window_border = "none", -- Remove border for true fullscreen
		integrations = {
			grep_in_directory = "fzf-lua",
			grep_in_selected = "fzf-lua",
		},

		keymaps = {
			open_file_in_vertical_split = "<c-v>",
			open_file_in_horizontal_split = "<c-s>",
			open_file_in_tab = "<c-t>",
			grep_in_directory = false,
		},
	})
end)

lazy.on_cmd("Yazi", setup)

vim.keymap.set("n", "<leader>-", function()
	setup()
	vim.cmd.Yazi()
end, { desc = "Toggle Yazi" })
