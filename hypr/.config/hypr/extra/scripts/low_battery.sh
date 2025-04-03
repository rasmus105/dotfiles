#!/bin/sh

while true; do
    battery=$(upower -i "$(upower -e | grep BAT)" | grep -E "percentage" | awk '{print $2}' | tr -d '%')

    if [ "$battery" -le "30" ]; then
        notify-send --urgency=critical --expire-time=10000 "Low battery: ${battery}%" 
        sleep 60
    else
        sleep 120
    fi
done
