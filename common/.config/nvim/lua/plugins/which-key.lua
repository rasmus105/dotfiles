local lazy = require("config.lazy")

local function setup()
	lazy.packadd("which-key.nvim")
	require("which-key").setup({
		delay = 150,
		expand = function()
			return true
		end,
	})
end

lazy.on_vimenter(setup)
