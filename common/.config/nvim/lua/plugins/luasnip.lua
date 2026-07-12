local lazy = require("config.lazy")
local M = {}

M.setup = lazy.once("luasnip", function()
	lazy.packadd("LuaSnip")

	local luasnip = require("luasnip")

	luasnip.setup({
		enable_autosnippets = true,
		region_check_events = { "CursorMoved", "CursorMovedI", "InsertEnter" },
	})

	require("luasnip.loaders.from_lua").lazy_load({
		paths = vim.fn.stdpath("config") .. "/lua/snippets",
	})
end)

lazy.on_event("InsertEnter", "LuaSnip", M.setup, { once = true })

return M
