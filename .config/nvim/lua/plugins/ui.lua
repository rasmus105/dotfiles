return {
	{
		"snacks.nvim",
		opts = {
			scroll = { enabled = false },
		},
		keys = {},

		-- Animations
	},

	{
		"folke/noice.nvim",
		enabled = true,
		require("noice").setup({
			cmdline = {
				view = "cmdline",
			},
		}),
	},

	-- statusline
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			local LazyVim = require("lazyvim.util")
			opts.sections.lualine_c[4] = {
				LazyVim.lualine.pretty_path({
					length = 0,
					relative = "cwd",
					modified_hl = "MatchParen",
					directory_hl = "",
					filename_hl = "Bold",
					modified_sign = "",
					readonly_icon = " 󰌾 ",
				}),
			}
		end,
	},

	{ -- TODO CHECK
		"MeanderingProgrammer/render-markdown.nvim",
		enabled = true,
	},

	{
		"folke/snacks.nvim",
		opts = {
			dashboard = {
				preset = {
					header = [[
        ███╗   ██╗██╗   ██╗██╗███╗   ███╗
        ████╗  ██║██║   ██║██║████╗ ████║
        ██╔██╗ ██║██║   ██║██║██╔████╔██║
        ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
        ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
        ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
                    ]],
				},
			},
		},
	},
}
