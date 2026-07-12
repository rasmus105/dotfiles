local lazy = require("config.lazy")

local setup = lazy.once("crates", function()
	lazy.packadd("crates.nvim")
	require("crates").setup({
		completion = {
			crates = {
				enabled = true,
				min_chars = 1,
			},
		},
		lsp = {
			enabled = true,
			actions = true,
			completion = true,
			hover = true,
		},
	})
end)

lazy.on_event({ "BufReadPre", "BufNewFile" }, "Crates", setup, { pattern = "Cargo.toml", once = true })
