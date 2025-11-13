#!/bin/bash

# The name of your laptop's monitor
LAPTOP_MONITOR="eDP-1"

# Check if an external monitor is connected
EXTERNAL_MONITOR=$(hyprctl -j monitors | jq -r '[.[] | select(.name != "eDP-1")][0].name')

# Get current workspace so we can switch back to it later.
CURRENT_WORKSPACE=$(hyprctl -j activeworkspace | jq -r '.id')

if [ -n "$EXTERNAL_MONITOR" ]; then
    echo "External monitor ($EXTERNAL_MONITOR) detected."

    # Move workspaces 1-9 to the external monitor
    for i in {1..9}; do
        hyprctl dispatch moveworkspacetomonitor "$i $EXTERNAL_MONITOR"
    done

    # Move workspace 10 to the laptop monitor
    hyprctl dispatch moveworkspacetomonitor "10 $LAPTOP_MONITOR"

    if [ -n "$CURRENT_WORKSPACE" ]; then
        hyprctl dispatch workspace "$CURRENT_WORKSPACE"
    else
        # This could mean output from `hyprctl -j activeworkspace`
        # has changed.
        echo "WARN: Unable to retrieve current workspace"
        hyprctl dispatch workspace 1
    fi


else
    echo "No external monitor detected. No changes made."
fi
