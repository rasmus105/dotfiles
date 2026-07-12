local lazy = require("config.lazy")

lazy.on_event({ "BufReadPre", "BufNewFile" }, "Rustaceanvim", function()
	lazy.packadd("rustaceanvim")
end, { pattern = "*.rs", once = true })
