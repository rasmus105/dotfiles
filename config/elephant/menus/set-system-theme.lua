Name = "set-system-theme"
NamePretty = "Colorscheme"
Description = "Select system colorscheme"

function GetEntries()
    local entries = {}
    local themes_dir = os.getenv("HOME") .. "/.config/themes"
    local current_theme_link = os.getenv("HOME") .. "/.config/theme"

    -- Get current theme by reading symlink
    local theme_handle = io.popen("basename \"$(readlink '" .. current_theme_link .. "')\" 2>/dev/null")
    local current_theme = ""
    if theme_handle then
        current_theme = theme_handle:read("*l") or ""
        theme_handle:close()
    end

    -- Get all theme directories
    local dir_handle = io.popen("find -L '" .. themes_dir .. "' -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort")
    if not dir_handle then
        return entries
    end

    for theme_path in dir_handle:lines() do
        local theme = theme_path:match(".*/(.+)$")

        if theme then
            -- Find preview image
            local preview_path = nil
            local preview_handle = io.popen("find -L '" ..
            theme_path .. "' -maxdepth 1 -type f -name 'preview.png' 2>/dev/null | head -n 1")
            if preview_handle then
                preview_path = preview_handle:read("*l")
                preview_handle:close()
            end

            -- Fallback to first background image if no preview
            if not preview_path or preview_path == "" then
                local bg_handle = io.popen("find -L '" ..
                theme_path ..
                "/backgrounds' -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \\) 2>/dev/null | head -n 1")
                if bg_handle then
                    preview_path = bg_handle:read("*l")
                    bg_handle:close()
                end
            end

            -- Convert kebab-case to Title Case
            local display_name = theme:gsub("-", " "):gsub("(%a)([%w]*)", function(a, b)
                return a:upper() .. b:lower()
            end)

            -- Mark current theme with dot prefix
            if theme == current_theme then
                display_name = " " .. display_name
            end

            local entry = {
                Text = display_name,
                Value = theme,
                Actions = {
                    activate = "~/.local/bin/system-theme set " .. theme,
                },
            }

            -- Add preview if found
            if preview_path and preview_path ~= "" then
                entry.Preview = preview_path
                entry.PreviewType = "file"
            end

            table.insert(entries, entry)
        end
    end

    dir_handle:close()
    return entries
end
