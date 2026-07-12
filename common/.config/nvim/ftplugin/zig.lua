local map = vim.keymap.set
map({ "n", "v", "x" }, "<leader>m", ":T zig build<CR>", { buffer = true, desc = "zig build" })
