local map = vim.keymap.set
local bufnr = vim.api.nvim_get_current_buf()

map("n", "<leader>ca", function()
	vim.cmd.RustLsp("codeAction")
end, { silent = true, buffer = bufnr, desc = "Rust code action" })

map("n", "K", function()
	vim.cmd.RustLsp({ "hover", "actions" })
end, { silent = true, buffer = bufnr, desc = "Rust hover actions" })

map({ "n", "v", "x" }, "<leader>m", ":T cargo build<CR>", { buffer = true, desc = "cargo build" })
