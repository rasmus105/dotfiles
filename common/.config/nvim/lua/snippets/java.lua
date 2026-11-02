---@diagnostic disable: undefined-global

local banner = "// ===================================================================================================="

return {
	s({ trig = "//=", wordTrig = false, name = "comment section" }, {
		t(banner),
		t({ "", "// " }),
		i(1),
		t({ "", banner }),
	}),

	s({ trig = "jfile", name = "java file skeleton" }, {
		t("public class "),
		f(function()
			local name = vim.fn.expand("%:t:r")
			return name ~= "" and name or "Main"
		end),
		t({ " {", "    public static void main(String[] args) {", "        " }),
		i(1),
		t({ "", "    }", "}" }),
	}),
}
