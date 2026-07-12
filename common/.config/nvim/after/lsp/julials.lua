local julia_lsp = vim.fn.stdpath("data") .. "/mason/packages/julia-lsp/libexec/bin/julia-lsp"

local function julia_env_path(root_dir)
	if root_dir and vim.fn.filereadable(vim.fs.joinpath(root_dir, "Project.toml")) == 1 then
		return root_dir
	end

	local env = vim.fn.system({
		"julia",
		"--startup-file=no",
		"--history-file=no",
		"-e",
		"using Pkg; print(dirname(Pkg.Types.Context().env.project_file))",
	})

	if vim.v.shell_error == 0 then
		return vim.trim(env)
	end
end

return {
	cmd = function(dispatchers, config)
		return vim.lsp.rpc.start({ julia_lsp, julia_env_path(config.root_dir) }, dispatchers, {
			cwd = config.cmd_cwd,
			detached = config.detached,
			env = config.cmd_env,
		})
	end,
	root_dir = function(bufnr, on_dir)
		local name = vim.api.nvim_buf_get_name(bufnr)
		on_dir(vim.fs.root(name, { "Project.toml", "JuliaProject.toml", ".git" }) or vim.fn.getcwd())
	end,
}
