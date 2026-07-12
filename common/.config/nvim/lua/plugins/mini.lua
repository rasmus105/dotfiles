local lazy = require("config.lazy")

lazy.packadd("mini.icons")
require("mini.icons").setup()

lazy.packadd("mini.cursorword")
require("mini.cursorword").setup({
	delay = 0,
})
