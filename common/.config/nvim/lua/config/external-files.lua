local M = {}

-- Pdfs, images, videos
M.patterns = {
	-- images
	"*.png",
	"*.jpg",
	"*.jpeg",
	"*.gif",
	"*.webp",
	"*.bmp",
	"*.tif",
	"*.tiff",
	-- videos
	"*.mp4",
	"*.avi", -- video/x-msvideo
	"*.mkv", -- video/x-matroska
	"*.flv", -- video/x-flv
	"*.wmv", -- video/x-ms-wmv
	"*.mpeg", -- video/mpeg
	"*.mpg", -- often video/mpeg
	"*.ogv", -- video/ogg
	"*.webm", -- video/webm
	"*.mov", -- video/quicktime
	"*.3gp", -- video/3gpp
	"*.3g2", -- video/3gpp2
	"*.asf", -- video/x-ms-asf
	"*.ogm", -- video/x-ogm+ogg
	-- pdfs
	"*.pdf",
}

local extensions = {}
for _, pattern in ipairs(M.patterns) do
	extensions[pattern:sub(3)] = true
end

-- Return whether the selection was handled, including viewer-launch failures.
-- Falling back to an editor on failure would create the unwanted buffer again.
function M.open(filename)
	if not filename then
		return false
	end
	if filename:match("^file://") then
		filename = vim.uri_to_fname(filename)
	elseif filename:match("^%a[%w+.-]*://") then
		return false
	end

	local extension = filename:match("%.([^./]+)$")
	if not extension or not extensions[extension:lower()] or vim.fn.isdirectory(filename) == 1 then
		return false
	end

	local _, err = vim.ui.open(vim.fn.fnamemodify(filename, ":p"))
	if err then
		vim.notify(err, vim.log.levels.ERROR)
	end
	return true
end

return M
