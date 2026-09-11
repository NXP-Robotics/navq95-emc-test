#!/bin/bash
#
# WIFI EMC test: continuously sweep RF test mode continuous TX over a list of
# channels using control/wifi.sh. No network traffic (iperf) is used.
#
set -uo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONTROL="$SCRIPT_DIR/../control/wifi.sh"

# Seconds of continuous TX per sweep step.
DWELL="${DWELL:-30}"
# TX power in dBm (0-24).
POWER="${POWER:-15}"

# Sweep steps: "CHANNEL MODE BANDWIDTH"
# MODE: 11 = 2.4G [1x1], 3 = 5G [1x1]   BANDWIDTH: 0 = 20MHz
STEPS=(
    "1 11 0"
    "6 11 0"
    "11 11 0"
    "36 3 0"
    "40 3 0"
    "44 3 0"
    "48 3 0"
    "149 3 0"
    "153 3 0"
    "157 3 0"
    "161 3 0"
)

[ -x "$CONTROL" ] || { echo "missing $CONTROL" >&2; exit 1; }

CHILD=""

# Always leave the radio in a clean state.
cleanup() {
    if [ -n "$CHILD" ]; then
        pkill -TERM -P "$CHILD" 2>/dev/null || true   # the dwell 'sleep'
        kill -TERM "$CHILD" 2>/dev/null || true
        wait "$CHILD" 2>/dev/null || true
    fi
    "$CONTROL" --stop || true
}
trap cleanup EXIT
# Exit immediately on stop; the EXIT trap does the cleanup.
trap 'exit 0' INT TERM

while true; do
    for step in "${STEPS[@]}"; do
        read -r channel mode bandwidth <<< "$step"
        echo "sweep: channel=$channel mode=$mode bw=$bandwidth power=$POWER dwell=${DWELL}s"
        # Run in background and wait, so SIGTERM is handled without waiting
        # for the dwell to expire.
        "$CONTROL" -c "$channel" -m "$mode" -b "$bandwidth" -p "$POWER" -d "$DWELL" &
        CHILD=$!
        wait "$CHILD" || echo "step failed (channel=$channel), continuing"
        CHILD=""
    done
done
