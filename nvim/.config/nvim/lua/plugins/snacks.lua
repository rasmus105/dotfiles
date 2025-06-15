return {
	{
		"folke/snacks.nvim",
		priority = 950,
		lazy = false,

		opts = {
			-- Disabled plugins
			animate = { enabled = false },
			scroll = { enabled = false }, -- Smooth scrolling
			statuscolumn = { enabled = false }, -- Don't know?
			words = { enabled = false }, -- Disable word highlighting.
			terminal = { enabled = false },

			-- Enabled plugins
			picker = { enabled = true }, -- Similar to telescope -- Maybe remove?
			bigfile = { enabled = true }, -- Optimizations when working with big files
			explorer = { enabled = true }, -- File explorer
			indent = { enabled = true }, -- TODO Not working with alacritty + ueber...
			input = { enabled = true }, -- Input box at top
			quickfile = { enabled = true }, -- makes `nvim somefile.txt` faster (load plugins after opening)
			scope = { enabled = true }, -- Detects code scope
			notifier = { -- Notifications in top right
				enabled = true,
				timeout = 3000,
			},
			dashboard = {
				sections = {
					{ section = "header" },
					{ -- Empty space to align right pane with left pane.
						pane = 2,
						section = "terminal",
						cmd = 'echo ""',
						height = 5,
						padding = 1,
					},
					{ section = "keys", gap = 1, padding = 1 },
					{
						pane = 2,
						icon = " ",
						title = "Recent Files",
						section = "recent_files",
						indent = 2,
						padding = 1,
					},
					{ pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
					{
						pane = 2,
						icon = " ",
						title = "Git Status",
						section = "terminal",
						enabled = function()
							return Snacks.git.get_root() ~= nil
						end,
						cmd = "git status --short --branch --renames",
						height = 5,
						padding = 1,
						ttl = 5 * 60,
						indent = 3,
					},
					{ section = "startup" },
				},
			},
		},
		keys = {
			-- Toggle views
			{
				"<leader>e",
				function()
					Snacks.explorer()
				end,
				desc = "File Explorer",
			},
			{
				"<leader>n",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "Notification History",
			},
			{
				"<leader>un",
				function()
					Snacks.notifier.hide()
				end,
				desc = "Dismiss All Notifications",
			},
			{
				"<leader>:",
				function()
					Snacks.picker.command_history()
				end,
				desc = "Command History",
			},

			-- Searching
			{
				"\\f",
				function()
					Snacks.picker.files()
				end,
				desc = "Find Files",
			},
			{
				"\\a",
				function()
					Snacks.picker.files({ hidden = true })
				end,
				desc = "Find Files",
			},
			{
				"\\w",
				function()
					Snacks.picker.grep()
				end,
				desc = "Grep",
			},
			{
				"\\b",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Find Buffers",
			},
			{
				"\\h",
				function()
					Snacks.picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"\\d",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				'\\r"',
				function()
					Snacks.picker.registers()
				end,
				desc = "Registers",
			},
			{ -- Search for icons
				"\\i",
				function()
					Snacks.picker.icons()
				end,
				desc = "Icons",
			},
			{
				"\\p",
				function()
					Snacks.picker.projects()
				end,
				desc = "Find Projects",
			},
			{
				"<leader><space>",
				function()
					Snacks.picker.smart()
				end,
				desc = "Smart Find Files",
			},

			-- Git
			{
				"<leader>gg",
				function()
					Snacks.lazygit()
				end,
				desc = "Lazygit",
			},
			{
				"<leader>gl",
				function()
					Snacks.picker.git_log()
				end,
				desc = "Git Log",
			},
			{
				"<leader>gS",
				function()
					Snacks.picker.git_stash()
				end,
				desc = "Git Stash",
			},
			{
				"<leader>gs",
				function()
					Snacks.picker.git_status()
				end,
				desc = "Git Status",
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_files()
				end,
				desc = "Find Git Files",
			}, -- files used in git repo
			-- {
			-- 	"<leader>gd",
			-- 	function()
			-- 		Snacks.picker.git_diff()
			-- 	end,
			-- 	desc = "Git Diff (Hunks)",
			-- },
			{
				"<leader>gb",
				function()
					Snacks.picker.git_branches()
				end,
				desc = "Git Branches",
			},
			{
				"<leader>gL",
				function()
					Snacks.picker.git_log_line()
				end,
				desc = "Git Log Line",
			},
			{
				"<leader>gf",
				function()
					Snacks.picker.git_log_file()
				end,
				desc = "Git Log File",
			},

			-- Other
			{
				"<leader>cR",
				function()
					Snacks.rename.rename_file()
				end,
				desc = "Rename File",
			},

			{
				"gr",
				function()
					Snacks.picker.lsp_references()
				end,
				nowait = true,
				desc = "References",
			},

			{
				"gw",
				function()
					vim.cmd("normal! viwy")
					local word = vim.fn.getreg('"') -- Get yanked word from register
					Snacks.picker.grep({ search = word })
				end,
				nowait = true,
				desc = "References of word",
			},

			-- Other
			{
				"<leader>N",
				desc = "Neovim News",
				function()
					Snacks.win({
						file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
						width = 0.6,
						height = 0.6,
						wo = {
							spell = false,
							wrap = false,
							signcolumn = "yes",
							statuscolumn = " ",
							conceallevel = 3,
						},
					})
				end,
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Setup some globals for debugging (lazy-loaded)
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd -- Override print to use snacks for `:=` command

					-- Useful toggle mappings
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts") -- Toggle spelling
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw") -- Toggle text wrapping
					Snacks.toggle.diagnostics():map("<leader>td") -- Toggle diagnostics

					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>tL") -- Toggle relative line numbers
					Snacks.toggle.line_number():map("<leader>tl") -- Toggle line numbers

					Snacks.toggle.treesitter():map("<leader>tt") -- Toggle treesitter
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:map("<leader>tb") -- Toggle background
					Snacks.toggle.inlay_hints():map("<leader>th") -- Inlay hints (e.g. types in rust)
					Snacks.toggle.indent():map("<leader>ti") -- Toggle indent lines
					Snacks.toggle.dim():map("<leader>tD") -- Toggle graying out everything but focus of cursor
				end,
			})
		end,
	},
}
