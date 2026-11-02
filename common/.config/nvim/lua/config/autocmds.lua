-- Highlight on yank (neet visual feedback when yanking)
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Ensure cursorline stays off (workaround for vscode-diff.nvim leak)
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
	callback = function()
		-- Skip diff windows (let vscode-diff manage those)
		if not vim.wo.diff then
			vim.wo.cursorline = false
		end
	end,
})

-- Auto create dir when saving a file
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(event)
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(event)
		-- local exclude = { 'gitcommit' } -- don't remember position in commit messages
		local mark = vim.api.nvim_buf_get_mark(event.buf, "'")
		local lcount = vim.api.nvim_buf_line_count(event.buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "text", "markdown", "gitcommit", "typst", "tex" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spelllang = { "en", "da" }
		vim.opt_local.spell = true
		vim.opt_local.textwidth = 80
	end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"help",
		"lspinfo",
		"checkhealth",
		"qf",
		"grug-far",
	},
	callback = function(event)
		vim.keymap.set("n", "q", function()
			vim.cmd("close")
		end, { buffer = event.buf, silent = true, nowait = true })
	end,
})

local external_files = require("config.external-files")

vim.api.nvim_create_autocmd("BufReadCmd", {
	pattern = external_files.patterns,
	callback = function(event)
		local filename = vim.api.nvim_buf_get_name(event.buf)
		-- Virtual revisions belong to their plugin's BufReadCmd handler.
		if filename:match("^%a[%w+.-]*://") then
			return
		end

		-- Background loads need a buffer, but must not read binary data or open a viewer.
		vim.b[event.buf].external_file = true
		vim.bo[event.buf].buftype = "nofile"
		vim.bo[event.buf].swapfile = false
		vim.bo[event.buf].modifiable = true
		vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, { "Binary file: " .. filename })
		vim.bo[event.buf].modified = false
		vim.bo[event.buf].modifiable = false
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = external_files.patterns,
	callback = function(event)
		if not vim.b[event.buf].external_file or vim.fn.win_gettype() ~= "" or vim.wo.diff then
			return
		end

		local win = vim.api.nvim_get_current_win()
		local previous = vim.fn.bufnr("#")
		-- Let the caller finish setting up its windows before opening or replacing anything.
		vim.schedule(function()
			if
				not vim.api.nvim_win_is_valid(win)
				or vim.api.nvim_get_current_win() ~= win
				or vim.api.nvim_win_get_buf(win) ~= event.buf
				or vim.fn.win_gettype(win) ~= ""
				or vim.wo[win].diff
			then
				return
			end

			-- CodeDiff's single-file panes do not set the native 'diff' option.
			local lifecycle = package.loaded["codediff.ui.lifecycle"]
			if lifecycle and lifecycle.get_session(vim.api.nvim_win_get_tabpage(win)) then
				return
			end

			local _, err = vim.ui.open(vim.api.nvim_buf_get_name(event.buf))
			if err then
				vim.notify(err, vim.log.levels.ERROR)
				return
			end

			if
				previous == event.buf
				or not vim.api.nvim_buf_is_valid(previous)
				or not vim.bo[previous].buflisted
				or vim.bo[previous].buftype ~= ""
			then
				previous = vim.api.nvim_create_buf(true, false)
			end
			vim.api.nvim_win_set_buf(win, previous)
			if #vim.fn.win_findbuf(event.buf) == 0 then
				vim.api.nvim_buf_delete(event.buf, { force = true })
			end
		end)
	end,
})

-- Auto-jump to first quickfix item, close the quickfix window, and notify
local group = vim.api.nvim_create_augroup("QfAutoJumpClose", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = "qf",
	callback = function()
		-- Only act on the global quickfix list, not location lists
		if vim.fn.win_gettype(0) ~= "quickfix" then
			return
		end

		-- Defer so the window is fully created before we operate on it
		vim.schedule(function()
			local info = vim.fn.getqflist({ size = 1, items = 1, title = 1 })
			local size = info.size or 0

			pcall(vim.cmd, "silent! cclose") -- close the quickfix window
			if size > 0 then
				pcall(vim.cmd, "silent! cfirst") -- jump to the first entry
				pcall(vim.cmd, "silent! normal! zz") -- center
			end

			-- Build a helpful notification
			local title = info.title or "Quickfix"
			if size > 0 then
				local first = info.items and info.items[1] or nil
				local file, lnum, col, text = "", 1, 1, ""
				if first then
					if first.bufnr and first.bufnr > 0 then
						file = vim.api.nvim_buf_get_name(first.bufnr)
					end
					file = file ~= "" and file or (first.filename or "")
					lnum = first.lnum or 1
					col = first.col or 1
					text = first.text or ""
				end
				vim.notify(
					string.format("%s: %d items. Jumped to %s:%d:%d %s", title, size, file, lnum, col, text),
					vim.log.levels.INFO,
					{ title = "Quickfix" }
				)
			else
				vim.notify(
					string.format("%s is empty. Closed the list.", title),
					vim.log.levels.INFO,
					{ title = "Quickfix" }
				)
			end
		end)
	end,
})

vim.api.nvim_create_autocmd({
	"DirChanged",
	"BufEnter",
	"FocusGained",
}, {
	callback = function()
		local title = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
		vim.o.titlestring = title:gsub("[%c\027]", "")
	end,
})

-- Suppress the E211 "File no longer available" error that fires when yazi
-- (or any external tool) deletes a buffer's file. Neovim's default
-- FileChangedShell handling for missing files is blocking (causes a
-- noticeable one-time lag) and only produces an error we don't care about.
-- Returning true marks the buffer as not-modified so it can be closed cleanly.
vim.api.nvim_create_autocmd("FileChangedShell", {
	group = vim.api.nvim_create_augroup("SuppressE211", { clear = true }),
	callback = function(ev)
		local bufname = vim.api.nvim_buf_get_name(ev.buf)
		if bufname ~= "" and vim.fn.filereadable(bufname) == 0 then
			vim.bo[ev.buf].modified = false
			return true
		end
	end,
})
