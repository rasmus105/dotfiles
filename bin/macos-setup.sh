#!/usr/bin/env bash
set -euo pipefail

defaults write com.apple.Terminal FocusFollowsMouse -bool true # avoid having to click once to focus on a window
defaults write com.apple.dock mru-spaces -bool false # avoid MacOS reordering desktops.
defaults write com.apple.dock autohide -bool true # automatically hide dock.
defaults write com.apple.dock autohide-time-modifier -float 0.30 # increase animation speed of dock appearing
defaults write com.apple.dock autohide-delay -float 0 # immediately show dock when moving cursor to the bottom.
defaults write com.apple.dock show-recents -bool false # don't show recent apps in dock
defaults write com.apple.CrashReporter DialogType -string server # suppress crash dialogs while keeping crash logs
defaults write com.apple.dock workspaces-auto-swoosh -bool true

# Stop the app before writing its preferences so it cannot overwrite them.
switcher_domain="com.interversehq.InstantSpaceSwitcher"
switcher_service="gui/$(id -u)/com.dotfiles.instant-space-switcher"
launchctl bootout "$switcher_service" 2>/dev/null || true
killall InstantSpaceSwitcher 2>/dev/null || true

# InstantSpaceSwitcher stores ANSI key codes and Carbon's Control mask (4096).
space_key_codes=(18 19 20 21 23 22 26 28 25 29)
for index in "${!space_key_codes[@]}"; do
    space_number=$((index + 1))
    digit=$((space_number % 10))
    hotkey_data="$(printf '{"keyCode":%s,"modifiers":4096,"displayKey":"%s","keyEquivalent":"%s"}' \
        "${space_key_codes[index]}" "$digit" "$digit" | xxd -p -c 256)"
    defaults write "$switcher_domain" "hotkey.space$space_number" -data "$hotkey_data"
    defaults write "$switcher_domain" "enabled.space$space_number" -bool true
    # Disable macOS's competing numbered-desktop shortcuts (IDs 118..127).
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$((117 + space_number))" \
        '<dict><key>enabled</key><false/></dict>'
done
for action in left right lastSpace space{11..16}; do
    defaults write "$switcher_domain" "enabled.$action" -bool false
done
defaults write "$switcher_domain" swipeOverride -bool true
defaults write "$switcher_domain" gestureSpeed -float 2000

# enable disk encryption
if [ "$(fdesetup isactive)" = "false" ]; then
    sudo fdesetup enable "$(id -un)"
fi
settings_activator="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
if [[ -x "$settings_activator" ]]; then
    "$settings_activator" -u
fi
killall Dock # MacOS should restart this immediately by itself.
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.dotfiles.instant-space-switcher.plist"
