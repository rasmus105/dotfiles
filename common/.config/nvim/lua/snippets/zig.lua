---@diagnostic disable: undefined-global

local banner = "// ===================================================================================================="

local function is_titlecase_file()
	return vim.fn.expand("%:t:r"):match("^%u") ~= nil
end

local function zig_file_skeleton()
	local sections = { "Types" }

	if is_titlecase_file() then
		table.insert(sections, "Fields")
	end

	table.insert(sections, "Functions")
	table.insert(sections, "Public API")

	local lines = {
		'const std = @import("std");',
		"",
	}

	for _, section in ipairs(sections) do
		table.insert(lines, banner)
		table.insert(lines, "// " .. section)
		table.insert(lines, banner)
		table.insert(lines, "")
	end

	return lines
end

return {
	s({ trig = "//=", name = "comment section" }, {
		t(banner),
		t({ "", "// " }),
		i(1),
		t({
			"",
			banner,
		}),
	}),

	s({ trig = "zfile", name = "zig file skeleton" }, {
		f(zig_file_skeleton),
		i(1),
	}),
}
