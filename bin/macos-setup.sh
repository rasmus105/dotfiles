#!/usr/bin/env bash

defaults write com.apple.Terminal FocusFollowsMouse -bool true # avoid having to click once to focus on a window
defaults write com.apple.dock mru-spaces -bool false # avoid MacOS reordering desktops.
defaults write com.apple.dock autohide -bool true # automatically hide dock.
defaults write com.apple.dock autohide-time-modifier -float 0.30 # increase animation speed of dock appearing
defaults write com.apple.dock autohide-delay -float 0 # immediately show dock when moving cursor to the bottom.
defaults write com.apple.dock show-recents -bool false # don't show recent apps in dock

# enable disk encryption
if [ "$(fdesetup isactive)" = "false" ]; then
    sudo fdesetup enable "$(id -un)"
fi


killall Dock # MacOS should restart this immediately by itself.
