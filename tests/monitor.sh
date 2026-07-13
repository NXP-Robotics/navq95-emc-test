#!/bin/bash

echo none > /sys/class/leds/red:status/trigger
echo none > /sys/class/leds/green:status/trigger
echo none > /sys/class/leds/blue:status/trigger

RED_BRIGHTNESS=/sys/class/leds/red:status/brightness
GREEN_BRIGHTNESS=/sys/class/leds/green:status/brightness
BLUE_BRIGHTNESS=/sys/class/leds/blue:status/brightness

ON=1
OFF=0

if [ -n "$1" ]; then
    if [ "$1" = "off" ]; then
        echo $OFF > $RED_BRIGHTNESS
        echo $OFF > $GREEN_BRIGHTNESS
        echo $OFF > $BLUE_BRIGHTNESS
        exit 0
    fi
fi

set -euo pipefail

STATE=true
while true; do
    SERVICES=$(basename -a /usr/lib/systemd/system/emc-test-*)
    OUTPUT=$(systemctl is-active $SERVICES)

    if [ "$STATE" = true ]; then
        if echo $OUTPUT | tr ' ' '\n' | grep -qv '^active$'; then
            echo $ON > $RED_BRIGHTNESS
            echo $OFF > $GREEN_BRIGHTNESS
            echo $OFF > $BLUE_BRIGHTNESS
        else
            echo $OFF > $RED_BRIGHTNESS
            echo $ON > $GREEN_BRIGHTNESS
            echo $OFF > $BLUE_BRIGHTNESS
        fi
        STATE=false
    else
        echo $OFF > $RED_BRIGHTNESS
        echo $OFF > $GREEN_BRIGHTNESS
        echo $OFF > $BLUE_BRIGHTNESS
        STATE=true
    fi
    sleep 0.5
done
