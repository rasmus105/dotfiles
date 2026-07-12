local selected_group = "UserTablineSel"
local inactive_group = "UserTabline"
local fill_group = "UserTablineFill"

local function get_hl(name)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	return ok and hl or {}
end

local function setup_highlights()
	local normal = get_hl("Normal")

	vim.api.nvim_set_hl(0, selected_group, {
		fg = normal.fg or "#ebdbb2",
		bg = "#504945",
		bold = true,
	})
	vim.api.nvim_set_hl(0, inactive_group, {
		fg = "#a89984",
		bg = "#3c3836",
	})
	vim.api.nvim_set_hl(0, fill_group, {
		bg = "#3c3836",
	})
end

local function escape_tabline_text(text)
	return text:gsub("%%", "%%%%")
end

local function real_window_count(tabpage)
	local count = 0

	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		local ok, config = pcall(vim.api.nvim_win_get_config, win)
		if ok and config.relative == "" then
			count = count + 1
		end
	end

	return count
end

local function tab_buffer(tabnr)
	local buffers = vim.fn.tabpagebuflist(tabnr)
	local winnr = vim.fn.tabpagewinnr(tabnr)
	return buffers[winnr]
end

local function tab_filename(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return "[No Name]"
	end

	local filename = vim.fn.fnamemodify(path, ":t")
	if filename == "" then
		return path
	end

	return filename
end

local function file_icon(bufnr, filename)
	local ok, icons = pcall(require, "mini.icons")
	if not ok then
		return "", nil
	end

	if filename == "[No Name]" then
		local filetype = vim.bo[bufnr].filetype
		if filetype ~= "" then
			local icon, hl = icons.get("filetype", filetype)
			return icon or "", hl
		end

		return "", nil
	end

	local icon, hl = icons.get("file", filename)
	return icon or "", hl
end

local function icon_group(icon_hl, tab_hl, selected)
	local suffix = icon_hl or "Default"
	suffix = suffix:gsub("[^%w_]", "_")

	local group = string.format("UserTablineIcon%s%s", selected and "Sel" or "", suffix)
	local icon = get_hl(icon_hl or "")
	local tab = get_hl(tab_hl)

	vim.api.nvim_set_hl(0, group, {
		fg = icon.fg or tab.fg,
		bg = tab.bg,
		bold = selected,
	})

	return group
end

function _G.UserTabline()
	local current_tab = vim.fn.tabpagenr()
	local parts = {}

	for tabnr, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		local selected = tabnr == current_tab
		local tab_hl = selected and selected_group or inactive_group
		local bufnr = tab_buffer(tabnr)
		local filename = tab_filename(bufnr)
		local icon, icon_hl = file_icon(bufnr, filename)
		local icon_hl_group = icon_group(icon_hl, tab_hl, selected)
		local window_count = real_window_count(tabpage)

		table.insert(parts, string.format("%%%dT", tabnr))
		table.insert(parts, "%#" .. tab_hl .. "# ")
		table.insert(parts, "%#" .. icon_hl_group .. "#" .. escape_tabline_text(icon))
		table.insert(
			parts,
			string.format(
				"%%#%s# %s [%d] ",
				tab_hl,
				escape_tabline_text(filename),
				window_count
			)
		)
	end

	table.insert(parts, "%#" .. fill_group .. "#%T")
	return table.concat(parts)
end

setup_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("UserTablineHighlights", { clear = true }),
	callback = setup_highlights,
})

vim.o.showtabline = 1
vim.o.tabline = "%!v:lua.UserTabline()"
