local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })
autocmd("BufWritePost", {
	group = "__formatter__",
	command = ":FormatWrite",
})
-- Utilities for creating configurations
local util = require("formatter.util")

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup({
	-- Enable or disable logging
	logging = true,
	-- Set the log level
	log_level = vim.log.levels.WARN,
	-- All formatter configurations are opt-in
	filetype = {
		-- Formatter configurations for filetype "lua" go here
		-- and will be executed in order
		lua = {
			-- "formatter.filetypes.lua" defines default configurations for the
			-- "lua" filetype
			require("formatter.filetypes.lua"),

			-- You can also define your own configuration
			function()
				-- Supports conditional formatting
				-- if util.get_current_buffer_file_name() == "special.lua" then
				--   return nil
				-- end

				-- Full specification of configurations is down below and in Vim help
				-- files
				return {
					exe = "stylua",
					args = {
						"--search-parent-directories",
						"--stdin-filepath",
						util.escape_path(util.get_current_buffer_file_path()),
						"--",
						"-",
					},
					stdin = true,
				}
			end,
		},

		cpp = {

			require("formatter.filetypes.cpp"),

			function()
				return {
					exe = "clang-format",
					args = { '-style=file:"/home/rasmus105/.config/nvim/after/plugin/.clang-format"' },
					stdin = true,
					cwd = vim.fn.expand("%:p:h"),
				}
			end,
		},
		c = {
			require("formatter.filetypes.c"),

			function()
				return {
					exe = "clang-format",
					args = { '-style=file:"/home/rasmus105/.config/nvim/after/plugin/.clang-format"' },
					stdin = true,
					cwd = vim.fn.expand("%:p:h"),
				}
			end,
		},
		python = {

			require("formatter.filetypes.python"),

			function()
				return {
					exe = "black",
					args = { "-q", "--stdin-filename", util.escape_path(util.get_current_buffer_file_name()), "-" },
					stdin = true,
				}
			end,
		},
		rust = {
			require("formatter.filetypes.rust"),

			function()
				return {
					exe = "rustfmt",
					args = { "--emit=stdout" },
					stdin = true,
				}
			end,
		},

		-- Use the special "*" filetype for defining formatter configurations on
		-- any filetype
		["*"] = {
			-- "formatter.filetypes.any" defines default configurations for any
			-- filetype
			require("formatter.filetypes.any").remove_trailing_whitespace,
		},
	},
})
