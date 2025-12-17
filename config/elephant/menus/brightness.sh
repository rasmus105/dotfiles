# Script Options

PROMPT="Select Monitor 󰍹"

#####

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/common.sh"

# Call ddcutil detect once and store output
DDCUTIL_OUTPUT=$(ddcutil detect)

# Parse monitors and bus information from ddcutil detect output
# Format for menu: "MODEL (DRM_CONNECTOR)"
# Also store bus mapping: "DRM_CONNECTOR:BUS_NUMBER"
MONITOR_INFO=$(echo "$DDCUTIL_OUTPUT" | awk '
# If a valid display, set valid and clear all vars
/^Display [0-9]/ {valid=1; drm=""; model=""; bus="";}

# If invalid display ensure not valid
/^Invalid display/ {valid=0;}

# Set bus number from I2C bus line
valid && /I2C bus:/ {
    gsub(/.*\/dev\/i2c-/, "", $0)
    gsub(/[^0-9].*/, "", $0)
    bus=$0
}

# Set drm to second word on line with "DRM_connector:"
valid && /DRM_connector:/ {drm=$2;}

# Set model to text after colon on line with "Model:"
valid && /Model:/ {
  model=substr($0, index($0, ":")+1)
  gsub(/^[ \t]+|[ \t]+$/, "", model)
}

# Print the menu entry and bus mapping
valid && drm && model && bus {
    print "MENU:" model " (" drm ")"
    print "BUS:" drm ":" bus
    drm=""; model=""; bus="";
}
')

# Extract just the menu options
MONITORS=$(echo "$MONITOR_INFO" | grep "^MENU:" | sed 's/^MENU://')

# Show menu with monitor options
SELECTED_MONITOR=$(menu "$PROMPT" "$MONITORS")

# Exit if no monitor selected
if [ -z "$SELECTED_MONITOR" ]; then
    exit 0
fi

# Extract DRM connector from selection (text between parentheses)
DRM_CONNECTOR=$(echo "$SELECTED_MONITOR" | sed -n 's/.*(\(.*\)).*/\1/p')

# Prompt for brightness percentage
BRIGHTNESS=$(menu_input "Enter brightness in % (0-100)")

# Exit if no brightness value entered
if [ -z "$BRIGHTNESS" ]; then
    exit 0
fi

# Validate brightness is a number between 0-100
if ! [[ "$BRIGHTNESS" =~ ^[0-9]+$ ]] || [ "$BRIGHTNESS" -lt 0 ] || [ "$BRIGHTNESS" -gt 100 ]; then
    notify-send "Invalid brightness value" "Please enter a number between 0 and 100"
    exit 1
fi

# Get bus number from stored monitor info
BUS_NUMBER=$(echo "$MONITOR_INFO" | grep "^BUS:$DRM_CONNECTOR:" | cut -d: -f3)

# Set brightness using ddcutil
run-notify ddcutil --bus="$BUS_NUMBER" setvcp 10 "$BRIGHTNESS"
