#!/bin/bash

RED=11
GREEN=12
BLUE=13

if [ -n "$1" ]; then
    if [ "$1" = "off" ]; then
        gpioset gpiochip5 $RED=0
        gpioset gpiochip5 $GREEN=0
        gpioset gpiochip5 $BLUE=0
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
            gpioset gpiochip5 $RED=1
            gpioset gpiochip5 $GREEN=0
            gpioset gpiochip5 $BLUE=0
        else
            gpioset gpiochip5 $RED=0
            gpioset gpiochip5 $GREEN=1
            gpioset gpiochip5 $BLUE=0
        fi
        STATE=false
    else
        gpioset gpiochip5 $RED=0
        gpioset gpiochip5 $GREEN=0
        gpioset gpiochip5 $BLUE=0
        STATE=true
    fi
    sleep 0.5
done
