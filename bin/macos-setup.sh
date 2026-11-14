#!/usr/bin/env bash
set -euo pipefail

# https://github.com/biscuitehh/pam-watchid supports Touch ID and Apple Watch.
# Sudo's remaining PAM rules allow passwords when the prompt is cancelled.
(
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT
    swiftc "$repo_dir/vendor/pam-watchid/watchid-pam-extension.swift" \
        -emit-library -o "$temp_dir/pam_watchid.so.2"

    pam_module=/usr/local/lib/pam/pam_watchid.so.2
    pam_config=/etc/pam.d/sudo_local
    pam_line="auth       sufficient     $pam_module"
    sudo install -d -o root -g wheel -m 755 /usr/local/lib/pam
    sudo install -o root -g wheel -m 444 "$temp_dir/pam_watchid.so.2" "$pam_module"
    if [[ -f "$pam_config" ]]; then
        cat "$pam_config" > "$temp_dir/sudo_local"
    else
        : > "$temp_dir/sudo_local"
    fi
    if ! grep -Fxq "$pam_line" "$temp_dir/sudo_local"; then
        printf '\n%s\n' "$pam_line" >> "$temp_dir/sudo_local"
        sudo install -o root -g wheel -m 644 "$temp_dir/sudo_local" "$pam_config"
    fi
)

defaults write com.apple.Terminal FocusFollowsMouse -bool true # avoid having to click once to focus on a window
defaults write com.apple.dock mru-spaces -bool false # avoid MacOS reordering desktops.
defaults write com.apple.dock autohide -bool true # automatically hide dock.
defaults write com.apple.dock autohide-time-modifier -float 0.30 # increase animation speed of dock appearing
defaults write com.apple.dock autohide-delay -float 0 # immediately show dock when moving cursor to the bottom.
defaults write com.apple.dock show-recents -bool false # don't show recent apps in dock
defaults write com.apple.CrashReporter DialogType -string server # suppress crash dialogs while keeping crash logs
defaults write com.apple.dock workspaces-auto-swoosh -bool true

# Free Control+Command+F by moving macOS full-screen shortcuts to Control+Command+Shift+F.
defaults write -g NSUserKeyEquivalents -dict-add \
    'Enter Full Screen' '^@$f' \
    'Exit Full Screen' '^@$f' \
    'Toggle Full Screen' '^@$f'

# Free Control+Command+D for Ghostty; use Control+Command+Shift+D for dictionary lookup.
# Hotkey 70 takes the character "d" (100), ANSI key code (2), and Cocoa modifier mask.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 70 \
    '<dict>
        <key>enabled</key><true/>
        <key>value</key><dict>
            <key>parameters</key><array><integer>100</integer><integer>2</integer><integer>1441792</integer></array>
            <key>type</key><string>standard</string>
        </dict>
    </dict>'

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
defaults write "$switcher_domain" swipeOverride -bool false
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
