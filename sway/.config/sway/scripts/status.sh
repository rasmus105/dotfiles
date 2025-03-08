# The Sway configuration file in ~/.config/sway/config calls this script.
# You should see changes to the status bar after saving this script.
# If not, do "killall swaybar" and $mod+Shift+c to reload the configuration.

# Produces "21 days", for example
uptime_formatted=$(uptime | cut -d ',' -f1  | cut -d ' ' -f4,5)

# The abbreviated weekday (e.g., "Sat"), followed by the ISO-formatted date
# like 2018-10-06 and the time (e.g., 14:01)
date_formatted=$(date "+%a %F %H:%M")

# Get the Linux version but remove the "-1-ARCH" part
linux_version=$(uname -r | cut -d '-' -f1)

# Returns the battery status: "Full", "Discharging", or "Charging".
battery_status=$(cat /sys/class/power_supply/BAT0/status)
battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)

# Returns latptop screen brightness
screen_brightness=$(cat /sys/class/backlight/amdgpu_bl1/brightness)

audio_volume=$(pactl list sinks | awk '/State:.*RUNNING/ {p=1} p && /Volume:/ {print $5; exit}')

language=$(swaymsg -r -t get_inputs | awk '/1:1:AT_Translated_Set_2_keyboard/;/xkb_active_layout_name/' | grep -A1 '\b1:1:AT_Translated_Set_2_keyboard\b' | grep "xkb_active_layout_name" | awk -F '"' '{print $4}')

#Network
network=$(ip route get 1.1.1.1 | grep -Po '(?<=dev\s)\w+' | cut -f1 -d ' ')
# interface_easyname=$(dmesg | grep $network | grep renamed | awk 'NF>1{print $NF}')
ping=$(ping -c 1 www.google.es | tail -1| awk '{print $4}' | cut -d '/' -f 2 | cut -d '.' -f 1)

# Scripts to execute every often
# bash /home/rasmus105/.config/sway/low_battery.sh

# Symbols
if ! [ $network ]
then
    network_active="⛔"
else
    network_active="⇆"
fi


# Emojis and characters for the status bar (Noto fonts emoji)
# 💎 💻 💡 🔌 ⚡ 📁 \| ↑ ⌨
echo '|' ⌨  $language '|' ↑ $uptime_formatted '|' 🐧 $linux_version '|' $network_active $ping "ms" '|' 🎧 $audio_volume '|' 💻 $screen_brightness '|' 🔋 $battery_percentage% $battery_status '|' $date_formatted '|'
