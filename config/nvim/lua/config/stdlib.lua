local M = {}

local cache = {
	zig_std_dir = nil,
}

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "Stdlib" })
end

local function current_filetype()
	local ft = vim.bo.filetype
	if ft == nil or ft == "" then
		ft = vim.filetype.match({ buf = 0 }) or ""
	end
	return ft
end

local function zig_std_dir()
	if cache.zig_std_dir then
		return cache.zig_std_dir
	end

	local ok, proc = pcall(vim.system, { "zig", "env" }, { text = true })
	if not ok or not proc then
		notify("Failed to start `zig env`", vim.log.levels.ERROR)
		return nil
	end

	local res = proc:wait()
	if not res or res.code ~= 0 then
		notify("`zig env` failed" .. (res and res.stderr and (": " .. res.stderr) or ""), vim.log.levels.ERROR)
		return nil
	end

	local out = res.stdout or ""
	local dir = out:match('%.std_dir%s*=%s*"([^"]+)"')
	if not dir or dir == "" then
		notify("Could not parse .std_dir from `zig env` output", vim.log.levels.ERROR)
		return nil
	end

	cache.zig_std_dir = dir
	return dir
end

function M.open()
	local ft = current_filetype()
	if ft == "zig" then
		local dir = zig_std_dir()
		if not dir then
			return
		end

		local entry = dir .. "/std.zig"
		vim.cmd.edit(vim.fn.fnameescape(entry))
		notify("Opened Zig stdlib: " .. dir)
		return
	end

	notify("Stdlib not implemented for filetype: " .. ft, vim.log.levels.WARN)
end

function M.search(query)
	local ft = current_filetype()
	if ft == "zig" then
		local dir = zig_std_dir()
		if not dir then
			return
		end

		local ok, fzf = pcall(require, "fzf-lua")
		if not ok then
			notify("fzf-lua is not available", vim.log.levels.ERROR)
			return
		end

		fzf.live_grep({
			cwd = dir,
			search = query,
			prompt = "zig-stdlib> ",
			rg_opts = table.concat({
				"--column",
				"--line-number",
				"--no-heading",
				"--color=always",
				"--smart-case",
				"--hidden",
				"--glob=*.zig",
				"--glob=!zig-cache/*",
				"--glob=!.git/*",
			}, " "),
		})
		return
	end

	notify("Stdlib search not implemented for filetype: " .. ft, vim.log.levels.WARN)
end

function M.setup()
	vim.api.nvim_create_user_command("Stdlib", function()
		M.open()
	end, { desc = "Open language stdlib" })

	vim.api.nvim_create_user_command("StdlibSearch", function(opts)
		M.search(opts.args)
	end, { desc = "Search language stdlib", nargs = "?" })
end

local map = vim.keymap.set

map("n", "<leader>l", function()
	require("config.stdlib").open()
end, { desc = "Open language stdlib" })

return M
