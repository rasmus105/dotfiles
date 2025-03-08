return {
	-- Incremental rename
	{
		"smjonas/inc-rename.nvim",
		enabled = false,
		cmd = "IncRename",
		config = true,
	},

	-- Go forward/backward with square brackets
	{ -- TODO CHECK
		"echasnovski/mini.bracketed",
		event = "BufReadPost",
		config = function()
			local bracketed = require("mini.bracketed")
			bracketed.setup({
				file = { suffix = "" },
				window = { suffix = "" },
				quickfix = { suffix = "" },
				yank = { suffix = "" },
				treesitter = { suffix = "n" },
			})
		end,
	},

	{
		"echasnovski/mini.cursorword",
		config = function()
			local cursorword = require("mini.cursorword")
			cursorword.setup({
				delay = 30,
			})
		end,
	},

	-- Better increase/descrease (+/-)
	{
		"monaqa/dial.nvim",
        -- stylua: ignore
        keys = {
        --{ "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
        --{ "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
                { "+", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
                { "-", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
        },
		enabled = false,
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal,
					augend.integer.alias.hex,
					augend.date.alias["%Y/%m/%d"],
					augend.constant.alias.bool,
					augend.semver.alias.semver,
					augend.constant.new({ elements = { "let", "const" } }),
				},
			})
		end,
	},

	-- copilot TODO CHECK AT SOME POINT
	--[[
	{
		"zbirenbaum/copilot.lua",
		opts = {
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept = "<C-l>",
					accept_word = "<M-l>",
					accept_line = "<M-S-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
			},
			filetypes = {
				markdown = true,
				help = true,
			},
		},
	}, ]]
}
