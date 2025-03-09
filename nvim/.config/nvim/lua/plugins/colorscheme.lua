return {
	{
		"ellisonleao/gruvbox.nvim",

		lazy = false, -- don't want to see flickering when opening neovim
		priority = 1000,

		opts = {
			terminal_colors = true, -- add neovim terminal colors
			undercurl = true,
			underline = true,
			bold = false,
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
			contrast = "", -- can be "hard", "soft" or empty string
			palette_overrides = {},
			overrides = {},
			dim_inactive = false,
			transparent_mode = false,
		},

		config = function(_, opts)
			require("gruvbox").setup(opts)
			vim.cmd([[
                silent! colorscheme gruvbox
                hi normal guibg=#292522
            ]])
		end,
	},

	-- Other popular colorschemes

	{ -- Fully supported colorscheme for testing
		"folke/tokyonight.nvim",
		enabled = false,
	},

	{
		"sainnhe/gruvbox-material",
		enabled = false,
	},

	{
		"sainnhe/everforest",
		enabled = true,
	},

	{
		"rebelot/kanagawa.nvim",
		enabled = false,
	},

	{
		"Mofiqul/dracula.nvim",
		enabled = false,
	},
}
