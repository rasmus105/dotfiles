# This script sets the laptop screen brightness to 5
# whenever the battery drops below 25 %,
# and ensures the brightness turns back up,
# when you start charging the device.
flag=false

while [ true ]
do
    battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)
    last_status=$(cat /home/rasmus105/.config/sway/data/last_status)
    battery_status=$(cat /sys/class/power_supply/BAT0/status)
    screen_brightness=$(cat /sys/class/backlight/amdgpu_bl1/brightness)

    last_brightness=$(cat /home/rasmus105/.config/sway/data/lastbrightness)

    if [ $battery_percentage -lt 25 ]  && [ $battery_status != "Charging" ]; then
        if [ $flag == false ]; then
            echo $screen_brightness > /home/rasmus105/.config/sway/data/lastbrightness
            flag=true
        fi
        echo 5 > /sys/class/backlight/amdgpu_bl1/brightness
    elif [ $battery_status != $last_status ] && [ $battery_status == "Charging" ] && [ $battery_percentage -lt 30 ]; then
        echo $last_brightness > /sys/class/backlight/amdgpu_bl1/brightness
        echo $screen_brightness > /home/rasmus105/.config/sway/data/lastbrightness
        flag=false
    fi

    echo $battery_status > /home/rasmus105/.config/sway/data/last_status
    sleep 1
done
