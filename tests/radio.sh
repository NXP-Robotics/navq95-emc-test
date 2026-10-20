#!/bin/bash
#
# Radio EMC test: combined WIFI + Bluetooth continuous TX sweep.
#
# WIFI RF test mode continuous TX (control/wifi.sh) and Bluetooth LE DTM
# continuous TX (control/bluetooth.sh) share the 2.4 GHz band, so they must
# never transmit at the same time. This script replaces the separate
# tests/wifi.sh and tests/bluetooth.sh sweeps: it walks one interleaved step
# list (one WIFI step, then one Bluetooth step, round-robin) and runs exactly
# one radio at a time, stopping it before starting the next step.
#
# No network traffic (iperf) and no BT scanning is used.
#
set -uo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WIFI_CONTROL="$SCRIPT_DIR/../control/wifi.sh"
BT_CONTROL="$SCRIPT_DIR/../control/bluetooth.sh"

# Seconds of continuous TX per sweep step.
DWELL="${DWELL:-1}"
# TX power in dBm. WIFI: 0-24. Bluetooth: -20..20, empty = module default.
POWER="${POWER:-10}"
WIFI_POWER="${WIFI_POWER:-$POWER}"
BT_POWER="${BT_POWER:-$POWER}"

# WIFI sweep steps: "CHANNEL MODE BANDWIDTH"
# MODE: 11 = 2.4G [1x1], 3 = 5G [1x1]   BANDWIDTH: 0 = 20MHz
WIFI_STEPS=(
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

# Bluetooth LE DTM channels to sweep (0..39, freq = 2402 + 2*CHANNEL MHz).
BT_STEPS=(39 0 9 19 29)

[ -x "$WIFI_CONTROL" ] || { echo "missing $WIFI_CONTROL" >&2; exit 1; }
[ -x "$BT_CONTROL" ] || { echo "missing $BT_CONTROL" >&2; exit 1; }

CHILD=""

# Kill the running step (if any) and leave both radios in a clean state.
cleanup() {
    if [ -n "$CHILD" ]; then
        pkill -TERM -P "$CHILD" 2>/dev/null || true   # the dwell 'sleep'
        kill -TERM "$CHILD" 2>/dev/null || true
        wait "$CHILD" 2>/dev/null || true
    fi
    "$WIFI_CONTROL" --stop || true
    "$BT_CONTROL" --stop || true
}
trap cleanup EXIT
# Exit immediately on stop; the EXIT trap does the cleanup.
trap 'exit 0' INT TERM

# Run one step in the background and wait for it, so SIGTERM is handled
# without waiting for the dwell to expire.
run_step() {
    "$@" &
    CHILD=$!
    wait "$CHILD"
    local rc=$?
    CHILD=""
    return $rc
}

wifi_step() {
    local channel mode bandwidth
    read -r channel mode bandwidth <<< "$1"
    echo "sweep: radio=wifi channel=$channel mode=$mode bw=$bandwidth power=$WIFI_POWER dwell=${DWELL}s"
    run_step "$WIFI_CONTROL" -c "$channel" -m "$mode" -b "$bandwidth" \
        -p "$WIFI_POWER" -d "$DWELL" ||
        echo "step failed (wifi channel=$channel), continuing"
    # Make sure the WIFI radio is off before the next (possibly BT) step.
    "$WIFI_CONTROL" --stop || true
}

bt_step() {
    local channel="$1"
    echo "sweep: radio=bluetooth channel=$channel power=${BT_POWER:-default} dwell=${DWELL}s"
    if [ -n "$BT_POWER" ]; then
        run_step "$BT_CONTROL" -c "$channel" -p "$BT_POWER" -d "$DWELL" ||
            echo "step failed (bluetooth channel=$channel), continuing"
    else
        run_step "$BT_CONTROL" -c "$channel" -d "$DWELL" ||
            echo "step failed (bluetooth channel=$channel), continuing"
    fi
    # Make sure the BT radio is off before the next (possibly WIFI) step.
    "$BT_CONTROL" --stop || true
}

# Start from a known state: both radios stopped.
"$WIFI_CONTROL" --stop || true
"$BT_CONTROL" --stop || true

bt_index=0
while true; do
    for wifi in "${WIFI_STEPS[@]}"; do
        wifi_step "$wifi"
        bt_step "${BT_STEPS[$bt_index]}"
        bt_index=$(( (bt_index + 1) % ${#BT_STEPS[@]} ))
    done
done
