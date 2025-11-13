local map = vim.keymap.set

---- Colorscheme configuration ----

require("gruvbox").setup({
	terminal_colors = true, -- add neovim terminal colors
	undercurl = true,
	underline = true,
	bold = true,
	italic = {
		strings = false,
		emphasis = true,
		comments = true,
		operators = false,
		folds = true,
	},
	strikethrough = true,
	invert_selection = false,
	invert_signs = false,
	invert_tabline = false,
	invert_intend_guides = false,
	inverse = true, -- invert background for search, diffs, statuslines and errors
	contrast = "", -- can be 'hard', 'soft' or empty string
	palette_overrides = {},
	overrides = {},
	dim_inactive = false,
	transparent_mode = false,
})

---- Custom colorschemes ----
local select_custom_gruvbox = function()
	vim.cmd(":set background=dark")
	vim.cmd.colorscheme("gruvbox")
	vim.cmd(":hi normal guibg=#292522")
end

---- Select the default colorscheme ----
select_custom_gruvbox()
