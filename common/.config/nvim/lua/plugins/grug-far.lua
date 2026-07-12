local lazy = require("config.lazy")

local setup = lazy.once("grug-far", function()
	lazy.packadd("grug-far.nvim")
	require("grug-far").setup()
end)

lazy.on_cmd({ "GrugFar", "GrugFarWithin" }, setup)

vim.keymap.set("n", "<leader>z", function()
	setup()
	require("grug-far").open()
end, { desc = "Search & Replace" })
