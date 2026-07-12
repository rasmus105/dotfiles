local M = {
	loaded = {},
	once_results = {},
}

local unpack = unpack or table.unpack

local function pack(...)
	return { n = select("#", ...), ... }
end

function M.packadd(name)
	if M.loaded[name] then
		return
	end

	vim.cmd.packadd(name)
	M.loaded[name] = true
end

function M.del_user_command(name)
	pcall(vim.api.nvim_del_user_command, name)
end

function M.once(key, fn)
	return function(...)
		local cached = M.once_results[key]
		if cached then
			return unpack(cached, 1, cached.n)
		end

		local results = pack(fn(...))
		M.once_results[key] = results
		return unpack(results, 1, results.n)
	end
end

function M.on_vimenter(fn)
	if vim.v.vim_did_enter == 1 then
		vim.schedule(fn)
		return
	end

	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("UserLazyVimEnter", { clear = false }),
		once = true,
		callback = function()
			vim.schedule(fn)
		end,
	})
end

function M.on_cmd(commands, fn)
	vim.api.nvim_create_autocmd("CmdUndefined", {
		group = vim.api.nvim_create_augroup("UserLazyCmd", { clear = false }),
		pattern = commands,
		callback = fn,
	})
end

function M.on_event(events, name, fn, opts)
	opts = opts or {}

	local callback = fn
	if opts.schedule then
		callback = function(args)
			vim.schedule(function()
				fn(args)
			end)
		end
	end

	vim.api.nvim_create_autocmd(events, {
		group = vim.api.nvim_create_augroup("UserLazy" .. name, { clear = true }),
		pattern = opts.pattern,
		once = opts.once,
		desc = opts.desc,
		callback = callback,
	})
end

return M
