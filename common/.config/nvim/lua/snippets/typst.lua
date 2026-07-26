return {
	s({ trig = "date", name = "current date" }, {
		f(function()
			return os.date("%Y-%m-%d")
		end),
	}),
}
