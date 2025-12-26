local map = vim.keymap.set

require("gitsigns").setup({
	-- Signs off by default, toggle with <leader>tg
	signcolumn = false,

	-- Blame off by default, toggle with <leader>tb
	current_line_blame = false,

	-- Word diff for character-level highlighting in previews
	word_diff = false,

	preview_config = {
		-- Options passed to nvim_open_win
		border = "none",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},

	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function opts(desc)
			return { buffer = bufnr, desc = desc }
		end

		-- Navigation between hunks
		map("n", "]h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end, opts("Next hunk"))

		map("n", "[h", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end, opts("Previous hunk"))

		-- Stage/unstage hunks
		map("n", "<leader>s", gitsigns.stage_hunk, opts("Stage hunk"))
		map("n", "<leader>r", gitsigns.reset_hunk, opts("Reset hunk"))

		-- Stage/reset in visual mode (partial hunk)
		map("v", "<leader>s", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, opts("Stage selected lines"))
		map("v", "<leader>r", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, opts("Reset selected lines"))

		-- Stage/reset entire buffer
		map("n", "<leader>S", gitsigns.stage_buffer, opts("Stage buffer"))
		map("n", "<leader>R", gitsigns.reset_buffer, opts("Reset buffer"))

		-- Undo stage
		map("n", "<leader>gu", gitsigns.undo_stage_hunk, opts("Undo stage hunk"))

		-- Preview hunk (inline shows deleted lines as virtual text in buffer)
		map("n", "<leader>gp", gitsigns.preview_hunk_inline, opts("Preview hunk inline"))

		-- Blame
		map("n", "<leader>gb", function()
			gitsigns.blame_line({ full = true })
		end, opts("Blame line"))

		-- Toggles
		map("n", "<leader>tg", gitsigns.toggle_signs, opts("Toggle git signs"))
		map("n", "<leader>tb", gitsigns.toggle_current_line_blame, opts("Toggle line blame"))
	end,
})
