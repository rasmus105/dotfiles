local lazy = require("config.lazy")

local explorer_min_width = 20
local explorer_max_width = 40

local codediff_config = {
	highlights = {
		line_insert = "DiffAdd", -- Line-level insertions
		line_delete = "DiffDelete", -- Line-level deletions
	},
	-- File explorer
	explorer = {
		view_mode = "tree",
		width = explorer_max_width,
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

local function fit_explorer(tabpage)
	local explorer = require("codediff.ui.lifecycle").get_explorer(tabpage)
	if not explorer or not explorer.winid or not vim.api.nvim_win_is_valid(explorer.winid) then
		return
	end

	local max_line_width = 0
	local status_margin = codediff_config.explorer.status_right_margin or 1
	local lines = vim.api.nvim_buf_get_lines(explorer.bufnr, 0, -1, false)

	for line_number, line in ipairs(lines) do
		local rendered = line:gsub("%s+$", "")
		local node = explorer.tree:get_node(line_number)
		local status = node and node.data and node.data.status_symbol

		if status and status ~= "" then
			local content = rendered:match("^(.-)%s+" .. vim.pesc(status) .. "$")
			if content then
				rendered = content .. "  " .. status .. string.rep(" ", status_margin)
			end
		end

		max_line_width = math.max(max_line_width, vim.fn.strdisplaywidth(rendered))
	end

	local width = math.max(explorer_min_width, math.min(explorer_max_width, max_line_width + 1))
	local config = require("codediff.config")
	config.options.explorer.width = width
	explorer.split._size = width
	vim.api.nvim_win_set_width(explorer.winid, width)
	explorer.tree:render()
end

local codediff_ui_group = vim.api.nvim_create_augroup("CodeDiffUi", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = codediff_ui_group,
	pattern = "CodeDiffOpen",
	callback = function(event)
		local tabpage = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()

		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
			local bufnr = vim.api.nvim_win_get_buf(win)

			if vim.bo[bufnr].filetype == "codediff-explorer" then
				vim.wo[win].statuscolumn = ""
			end
		end

		fit_explorer(tabpage)
		vim.cmd("redraw")
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = codediff_ui_group,
	pattern = "CodeDiffClose",
	callback = function()
		require("codediff.config").options.explorer.width = explorer_max_width
	end,
})

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
