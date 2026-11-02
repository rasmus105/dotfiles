local FILE_SIZE_LIMIT = 2 * 1024 * 1024
local LONG_LINE_MIN_SIZE = 10 * 1024
local AVERAGE_LINE_LIMIT = 1000

local function activate(bufnr, path, size, reason)
	vim.b[bufnr].bigfile = true
	vim.b[bufnr].bigfile_reason = reason
	vim.b[bufnr].bigfile_size = size

	-- Keep every big-file mode setting here so its behavior is easy to audit.
	vim.bo[bufnr].undofile = false
	vim.b[bufnr].completion = false
	vim.b[bufnr].minicursorword_disable = true
	vim.b[bufnr].matchparen_timeout = 10
	vim.b[bufnr].matchparen_insert_timeout = 10
	vim.diagnostic.enable(false, { bufnr = bufnr })

	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local filename = vim.fn.fnamemodify(path, ":t")
		vim.notify(
			string.format("Big-file mode: %s (%.1f MiB, %s)", filename, size / (1024 * 1024), reason),
			vim.log.levels.INFO,
			{ title = "Neovim" }
		)
	end)
end

vim.filetype.add({
	pattern = {
		[".*"] = {
			function(path, bufnr)
				if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end

				local size = vim.fn.getfsize(path)
				if size <= 0 then
					return
				end

				local reason
				if size >= FILE_SIZE_LIMIT then
					reason = "file size"
				else
					local line_count = math.max(vim.api.nvim_buf_line_count(bufnr), 1)
					if size >= LONG_LINE_MIN_SIZE and (size - line_count) / line_count >= AVERAGE_LINE_LIMIT then
						reason = "long lines"
					end
				end

				if reason then
					return "bigfile", function(buf)
						activate(buf, path, size, reason)
					end
				end
			end,
			{ priority = math.huge },
		},
	},
})

return {}
