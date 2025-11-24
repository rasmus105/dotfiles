Name = "menu"
NamePretty = "Menu"
FixedOrder = true
HideFromProviderlist = true
Description = "Menu"

function GetEntries()
    return {
        {
            Text = "Set System Theme",
            Icon = "",
            Actions = {
                ["set-system-theme"] = "walker -m menus:system-theme",
            },
        },
        {
            Text = "Set Brightness",
            Icon = "",
            Actions = {
                ["set-brightness"] = "walker -m menus:brightness",
            },
        },
        {
            Text = "System Refresh",
            Icon = "",
            Actions = {
                ["system-refresh"] =
                "systemd-run --user --collect bash -lc ~/.local/bin/system-refresh",
            },
        },
        {
            Text = "Install package",
            Icon = "󰣇",
            Actions = {
                ["install-package"] = "ghostty --class=TUI.float -e ~/.local/bin/package-install",
            },
        },
        {
            Text = "Remove package",
            Icon = "󰭌",
            Actions = {
                ["remove-package"] = "ghostty --class=TUI.float -e ~/.local/bin/package-remove",
            },
        },

        -- {
        --     Text = "Update",
        --     Icon = "",
        --     Actions = {
        --         ["update"] = "ghostty --class=local.floating -e update-perform",
        --     },
        -- },
        -- {
        --     Text = "Change themes",
        --     Icon = "󰸌",
        --     Actions = {
        --         ["change-themes"] = "walker -t menus -m menus:themes",
        --     },
        -- },
        -- {
        --     Text = "Capture",
        --     Icon = "",
        --     Actions = {
        --         ["capture"] = "walker -t menus -m menus:capture",
        --     },
        -- },
        -- {
        --     Text = "Setup",
        --     Icon = "󰉉",
        --     Actions = {
        --         ["setup"] = "walker -t menus -m menus:setup",
        --     },
        -- },
        -- {
        --     Text = "Tools",
        --     Icon = "",
        --     Actions = {
        --         ["tools"] = "walker -t menus -m menus:tools",
        --     },
        -- },
        -- {
        --     Text = "Keybindings",
        --     Icon = "",
        --     Actions = {
        --         ["keybindings"] = "walker -t menus -m menus:keybindings",
        --     },
        -- },
        -- {
        --     Text = "System",
        --     Icon = "󰐥",
        --     Actions = {
        --         ["system"] = "walker -t menus -m menus:system",
        --     },
        -- },
    }
end
