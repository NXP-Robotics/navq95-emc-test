#!/bin/bash
set -euo pipefail

IP_ADDR=$(ip -4 -o addr show mlan0 | awk '{print $4}' | cut -d/ -f1)

if [ -z "$IP_ADDR" ]; then
    exit 1
fi

echo $IP_ADDR

iw dev mlan0 set power_save off
iperf -c 192.168.0.1 -u -b 500M -l 1470 -t 0 -P 4 -B $IP_ADDR

exit 1
