#!/bin/bash
#
# Bluetooth EMC test: continuously sweep LE DTM continuous TX over a list of
# channels using control/bluetooth.sh. No BT scanning is used.
#
set -uo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONTROL="$SCRIPT_DIR/../control/bluetooth.sh"

# Seconds of continuous TX per sweep step.
DWELL="${DWELL:-30}"
# TX power in dBm (-20..20); empty = use module calibration default.
POWER="${POWER:-}"

# LE DTM channels to sweep (0..39, freq = 2402 + 2*CHANNEL MHz).
STEPS=(39 0 9 19 29)

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
    for channel in "${STEPS[@]}"; do
        echo "sweep: channel=$channel power=${POWER:-default} dwell=${DWELL}s"
        # Run in background and wait, so SIGTERM is handled without waiting
        # for the dwell to expire.
        if [ -n "$POWER" ]; then
            "$CONTROL" -c "$channel" -p "$POWER" -d "$DWELL" &
        else
            "$CONTROL" -c "$channel" -d "$DWELL" &
        fi
        CHILD=$!
        wait "$CHILD" || echo "step failed (channel=$channel), continuing"
        CHILD=""
    done
done
