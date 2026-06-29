#!/bin/bash
set -euo pipefail

cleanup() {
	echo "Ctrl-C detected, running command..."
	ip link set can0 down
	exit 0
}

trap cleanup SIGINT

ip link set can0 down
ip link set can0 type can bitrate 1000000 dbitrate 2000000 fd on
ip link set can0 up
cansend can0 123#01

while true; do
	sleep 1
done
