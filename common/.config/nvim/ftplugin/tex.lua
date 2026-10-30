local map = vim.keymap.set

local function pdf_for(file)
	return vim.fn.fnamemodify(file, ":r") .. ".pdf"
end

local function compile_current_file()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("Cannot compile an unnamed LaTeX buffer", vim.log.levels.WARN)
		return false
	end

	vim.cmd.update()

	local directory = vim.fn.fnamemodify(file, ":h")
	local filename = vim.fn.fnamemodify(file, ":t")
	local result = vim.system({
		"latexmk",
		"-pdf",
		"-interaction=nonstopmode",
		"-synctex=1",
		filename,
	}, { cwd = directory, text = true }):wait()

	if result.code ~= 0 then
		local error = vim.trim(result.stderr or "")
		if error == "" then
			error = vim.trim(result.stdout or "")
		end
		if error == "" then
			error = "latexmk exited with status " .. result.code
		end
		vim.notify("LaTeX compile failed:\n" .. error, vim.log.levels.ERROR)
		return false
	end

	return true
end

vim.api.nvim_buf_create_user_command(0, "LatexCompile", compile_current_file, {
	desc = "Compile current LaTeX file",
})

local function watch_current_file()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("Cannot watch an unnamed LaTeX buffer", vim.log.levels.WARN)
		return
	end

	if not compile_current_file() then
		return
	end

	local directory = vim.fn.fnamemodify(file, ":h")
	local filename = vim.fn.fnamemodify(file, ":t")
	vim.ui.open(pdf_for(file))

	local script = vim.fn.shellescape(
		'cd -- "$1" && latexmk -pdf -pvc -view=none -interaction=nonstopmode -synctex=1 "$2"; exec bash'
	)
	vim.cmd("T bash -c " .. script .. " _ " .. vim.fn.shellescape(directory) .. " " .. vim.fn.shellescape(filename))
end

map({ "n", "x" }, "<leader>m", watch_current_file, { buffer = true, desc = "LaTeX watch" })
