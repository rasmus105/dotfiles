local lazy = require("config.lazy")

local setup = lazy.once("yazi", function()
	lazy.packadd("plenary.nvim")
	lazy.packadd("yazi.nvim")
	local external_files = require("config.external-files")
	local openers = require("yazi.openers")
	-- Tab/split actions replace open_file_function, so intercept their shared openers too.
	for _, name in ipairs({
		"open_file",
		"open_file_in_vertical_split",
		"open_file_in_horizontal_split",
		"open_file_in_tab",
	}) do
		local open_file = openers[name]
		openers[name] = function(filename, ...)
			if not external_files.open(filename) then
				return open_file(filename, ...)
			end
		end
	end
	local open_multiple_files = openers.open_multiple_files
	openers.open_multiple_files = function(filenames, ...)
		local editable = {}
		for _, filename in ipairs(filenames) do
			if not external_files.open(filename) then
				editable[#editable + 1] = filename
			end
		end
		if #editable > 0 then
			return open_multiple_files(editable, ...)
		end
	end

	require("yazi").setup({
		open_file_function = openers.open_file,
		hooks = {
			yazi_opened_multiple_files = openers.open_multiple_files,
		},
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
