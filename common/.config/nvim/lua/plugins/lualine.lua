local lazy = require("config.lazy")

local function setup()
	lazy.packadd("lualine.nvim")

	local lualine = require("lualine")
	local icons = require("mini.icons")

	local function get_hl_fg(name)
		if not name then
			return nil
		end

		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
		if not ok or not hl.fg then
			return nil
		end

		return string.format("#%06x", hl.fg)
	end

	local function current_file_icon()
		local filename = vim.fn.expand("%:t")
		local extension = vim.fn.expand("%:e")
		local icon, hl, is_default = icons.get("file", filename)

		if is_default and extension ~= "" then
			local extension_icon, extension_hl, extension_is_default = icons.get("extension", extension)
			if not extension_is_default then
				icon, hl = extension_icon, extension_hl
			end
		end

		return icon or "", hl
	end

	local function current_filename()
		local filename = vim.fn.expand("%:t")
		local modified = vim.bo.modified and " [+]" or ""

		if filename == "" then
			return "[New Buffer]" .. modified
		end

		return filename .. modified
	end

	local config = {
		options = {
			component_separators = { left = "", right = "" },
			-- section_separators = { left = '', right = '' },
			section_separators = { left = "", right = "" },
			theme = "auto",
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = {
				{
					function()
						return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
					end,
					icon = "",
				},
				{
					function()
						return current_file_icon()
					end,
					color = function()
						local _, hl = current_file_icon()
						return { fg = get_hl_fg(hl), gui = "bold" }
					end,
					padding = { left = 1, right = 1 },
					separator = "",
				},
				{
					function()
						return current_filename()
					end,
					padding = { left = 0, right = 1 },
					color = { gui = "bold" },
				},
			},
			lualine_c = {
				{
					"diff",
					-- symbols = { added = ' ', modified = '󰜥 ', removed = ' ' },
					-- symbols = { added = ' ', modified = ' ', removed = ' ' },
					symbols = { added = " ", modified = "󰜥 ", removed = " " },
				},
				{
					"branch",
					icon = "",
				},
			},
			lualine_x = {
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = " ", warn = " ", info = " ", hint = " " },
				},
			},
			lualine_y = {
				{
					function()
						local clients = vim.lsp.get_clients({ bufnr = 0 })
						if next(clients) == nil then
							return "No Active Lsp"
						end

						return clients[1].name
					end,
					icon = " ",
				},
				{ "fileformat" },
				{ "encoding" },
				{ "filesize" },
			},
			lualine_z = { "%l:%c", "%p%% of %L" },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_y = {},
			lualine_z = {},
			lualine_c = {},
			lualine_x = {},
		},
	}

	lualine.setup(config)
end

lazy.on_vimenter(setup)
