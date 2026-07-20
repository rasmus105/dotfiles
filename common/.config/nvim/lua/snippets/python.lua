---@diagnostic disable: undefined-global

local banner = "# -----------------------------------------------------------------------------"

return {
	s({ trig = "#=", wordTrig = false, name = "comment section" }, {
		t(banner),
		t({ "", "# " }),
		i(1),
		t({ "", banner }),
	}),

	s({ trig = "main", name = "main guard" }, {
		t({ 'if __name__ == "__main__":', "\t" }),
		i(1, "main()"),
	}),

	s({ trig = "test", name = "pytest test" }, {
		t("def test_"),
		i(1, "name"),
		t({ "():", "\t" }),
		i(2, "assert True"),
	}),

	s({ trig = "fixture", name = "pytest fixture" }, {
		t({ "@pytest.fixture", "def " }),
		i(1, "fixture_name"),
		t({ "():", "\t" }),
		i(2),
	}),
}
