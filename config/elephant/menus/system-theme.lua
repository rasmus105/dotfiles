Name = "system-theme"
NamePretty = "System themes"
HideFromProviderlist = true
Cache = false
Parent = "themes"
Action = "~/.dotfiles/bin/system-set-theme '%VALUE%'"

function GetEntries()
    local entries = {}
    local home = os.getenv("HOME") or ""
    local dotfiles_dir = home .. "/.dotfiles"
    local themes_dir = dotfiles_dir .. "/themes"
    local current_theme_link = home .. "/.config/theme"
    local set_theme_script = dotfiles_dir .. "/bin/system-set-theme"

    local current_handle = io.popen("basename $(readlink '" .. current_theme_link .. "' 2>/dev/null) 2>/dev/null")
    local current_theme = ""
    if current_handle then
        current_theme = current_handle:read("*l") or ""
        current_handle:close()
    end

    local handle = io.popen(
        "find '" .. themes_dir .. "' -mindepth 1 -maxdepth 1 \\( -type d -o -type l \\) ! -name 'backgrounds' | sort"
    )
    if handle then
        for line in handle:lines() do
            local theme_name = line:match("([^/]+)$")

            if theme_name and theme_name ~= "backgrounds" then
                local display_name = theme_name:gsub("-", " "):gsub("(%a)([%w_']*)", function(first, rest)
                    return first:upper() .. rest
                end)

                local is_current = (theme_name == current_theme)
                local prefix = is_current and "* " or ""

                table.insert(entries, {
                    Text = prefix .. display_name,
                    Subtext = is_current and "Current theme" or "",
                    Value = theme_name,
                    state = is_current and { "current" } or nil,
                })
            end
        end
        handle:close()
    end

    if #entries == 0 then
        table.insert(entries, {
            Text = "No themes found",
            Subtext = "Check " .. themes_dir,
            Value = "",
        })
    end

    return entries
end
