local map = vim.keymap.set
local lazy = require("config.lazy")

local M = {}

M.setup = lazy.once("fzf-lua", function()
	lazy.packadd("fzf-lua")

	local fzf = require("fzf-lua")
	fzf.setup({
		previewers = {
			builtin = {
				extensions = {
					png = { "chafa", "{file}" },
					jpg = { "chafa", "{file}" },
					jpeg = { "chafa", "{file}" },
					webp = { "chafa", "{file}" },
					gif = { "chafa", "{file}" },
					bmp = { "chafa", "{file}" },
					tif = { "chafa", "{file}" },
					tiff = { "chafa", "{file}" },
					svg = { "chafa", "{file}" },
				},
			},
		},
		files = {
			previewer = "builtin",
		},
		buffers = {
			previewer = "builtin",
		},
		winopts = {
			fullscreen = true,
		},
		keymap = {
			builtin = {
				true,
			},
			fzf = {
				true,
				["ctrl-n"] = "down",
				["ctrl-p"] = "up",
				["ctrl-d"] = "page-down",
				["ctrl-u"] = "page-up",
				["ctrl-f"] = "forward-char",
				["ctrl-b"] = "backward-char",
				["ctrl-q"] = "select-all+accept",
			},
		},
	})

	return fzf
end)

local small_window = { fullscreen = false, height = 0.4, width = 0.2, row = 0.5, col = 0.5 }

local function fzf_call(method, opts)
	return function()
		M.setup()[method](opts)
	end
end

lazy.on_cmd("FzfLua", M.setup)

-- Find files
-- fff is currently lacking some functionality such as full screen and next/prev keybindings
-- map('n', '\\f', function() require('fff').find_files() end,
-- { desc = 'FFFind files' })
map("n", "\\f", fzf_call("files"), { desc = "Find files" })

-- Grep
map("n", "\\w", fzf_call("live_grep"), { desc = "Grep words" })

-- Find diagnostics
map("n", "\\d", fzf_call("diagnostics_workspace"), { desc = "Diagnostics" })

-- Search through open buffers
map("n", "\\b", fzf_call("buffers"), { desc = "Diagnostics" })

-- Fuzzy find quick fix list
map("n", "\\q", fzf_call("quickfix"), { desc = "Quickfix list" })

-- Fuzzy find git diff
map("n", "\\g", fzf_call("git_diff"), { desc = "Current git diff" })

-- Fuzzy find buffer git commits (file history)
map("n", "\\h", fzf_call("git_bcommits"), { desc = "Commit history for buffer" })

-- Stdlib
map("n", "\\s", function()
	require("config.stdlib").search()
end, { desc = "Search language stdlib" })

-- Fuzzy find colorschemes
map("n", "\\c", function()
	M.setup().colorschemes({
		winopts = small_window,
	})
end, { desc = "Fuzzy find colorschemes" })

-- Grep word on cursor
map("n", "gw", fzf_call("grep_cword"), { desc = "Grep for word cursor is on" })

map("n", "gr", fzf_call("lsp_references"), { desc = "LSP References (fzf-lua)", nowait = true })

map("n", "gd", fzf_call("lsp_definitions"), { desc = "LSP Definitions (fzf-lua)" })

return M
