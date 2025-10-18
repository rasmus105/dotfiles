local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Basic Options
config.default_prog = { '/bin/zsh' }
config.font = wezterm.font('Hack')
config.color_scheme = 'GruvboxDark'
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 524288 -- approximately 0.5 GB
config.cursor_blink_rate = 0

-- General Options
config.automatically_reload_config = true
config.window_decorations = "NONE"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"

-- print the workspace name at the upper right
wezterm.on("update-right-status", function(window, pane)
    window:set_right_status(window:active_workspace())
end)

-- load plugin for session manager
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
workspace_switcher.zoxide_path = "/usr/bin/zoxide"

wezterm.on("toggle-tabbar", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if overrides.enable_tab_bar == false then
        wezterm.log_info("tab bar shown")
        overrides.enable_tab_bar = true
    else
        wezterm.log_info("tab bar hidden")
        overrides.enable_tab_bar = false
    end
    window:set_config_overrides(overrides)
end)

config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false


-- keymaps
-- Key bindings
config.keys = {
    -- Reload config
    { key = 'r',     mods = 'CMD',       action = wezterm.action.ReloadConfiguration },

    -- Close
    { key = 'q',     mods = 'CMD',       action = wezterm.action.CloseCurrentPane { confirm = false } },

    -- Window decorations toggle
    { key = 'd',     mods = 'CMD',       action = wezterm.action.ToggleFullScreen },

    -- Panes
    { key = 'h',     mods = 'CMD',       action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'j',     mods = 'CMD',       action = wezterm.action.ActivatePaneDirection 'Down' },
    { key = 'k',     mods = 'CMD',       action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'l',     mods = 'CMD',       action = wezterm.action.ActivatePaneDirection 'Right' },

    { key = 'v',     mods = 'CMD',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 's',     mods = 'CMD',       action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

    { key = 'f',     mods = 'CMD',       action = wezterm.action.TogglePaneZoomState },

    -- Tabs
    { key = 'n',     mods = 'CMD',       action = wezterm.action.SpawnTab 'CurrentPaneDomain' },

    { key = '1',     mods = 'CMD',       action = wezterm.action.ActivateTab(0) },
    { key = '2',     mods = 'CMD',       action = wezterm.action.ActivateTab(1) },
    { key = '3',     mods = 'CMD',       action = wezterm.action.ActivateTab(2) },
    { key = '4',     mods = 'CMD',       action = wezterm.action.ActivateTab(3) },
    { key = '5',     mods = 'CMD',       action = wezterm.action.ActivateTab(4) },
    { key = '6',     mods = 'CMD',       action = wezterm.action.ActivateTab(5) },
    { key = '7',     mods = 'CMD',       action = wezterm.action.ActivateTab(6) },
    { key = '8',     mods = 'CMD',       action = wezterm.action.ActivateTab(7) },
    { key = '9',     mods = 'CMD',       action = wezterm.action.ActivateTab(8) },

    { key = ']',     mods = 'CMD',       action = wezterm.action.ActivateTabRelative(1) },
    { key = '[',     mods = 'CMD',       action = wezterm.action.ActivateTabRelative(-1) },

    -- Scrolling
    { key = 'u',     mods = 'CMD',       action = wezterm.action.ScrollByPage(-0.5) },
    { key = 'd',     mods = 'CMD',       action = wezterm.action.ScrollByPage(0.5) },

    -- Command palette
    { key = 'p',     mods = 'CMD',       action = wezterm.action.ActivateCommandPalette },
    { key = 'o',     mods = 'CMD',       action = wezterm.action.ShowLauncher },

    -- Search
    { key = '/',     mods = 'CMD',       action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },

    -- Tab bar and overview
    { key = 'x',     mods = 'CMD|SHIFT', action = wezterm.action.ShowTabNavigator },

    -- Unbind default keys
    { key = 'Enter', mods = 'CTRL',      action = wezterm.action.DisableDefaultAssignment },
    { key = 'Tab',   mods = 'CTRL',      action = wezterm.action.DisableDefaultAssignment },

    -- Workspace management
    { key = "t",     mods = "CMD",       action = workspace_switcher.switch_workspace() },
    { key = "t",     mods = "CMD|SHIFT", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

    { key = "b",     mods = "CMD",       action = wezterm.action.EmitEvent("toggle-tabbar") },
}

return config
