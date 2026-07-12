---- Colorscheme configuration ----

local lazy = require("config.lazy")

lazy.packadd("gruvbox.nvim")
lazy.packadd("alabaster.nvim")

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
	inverse = false, -- invert background for search, diffs, statuslines and errors
	contrast = "", -- can be 'hard', 'soft' or empty string
	palette_overrides = {},
	dim_inactive = false,
	transparent_mode = false,
	overrides = {
		Normal = { bg = "#292522" },
		-- Diff highlights adjusted for warmer background
		DiffAdd = { bg = "#3d4220" },
		DiffDelete = { bg = "#4a2828" },
		DiffChange = { bg = "#3a3520" },
		DiffText = { bg = "#5c5020", fg = "#ebdbb2" },
		-- vscode-diff.nvim highlight groups
		CodeDiffLineInsert = { bg = "#2a3525" },
		CodeDiffLineDelete = { bg = "#3a2525" },
		CodeDiffCharInsert = { bg = "#3d4a2a" },
		CodeDiffCharDelete = { bg = "#4a3030" },
		-- Invert search highlights for better visibility
		Search = { reverse = true },
		IncSearch = { reverse = true },
		CurSearch = { reverse = true },
	},
})

pcall(vim.cmd, "colorscheme gruvbox")
