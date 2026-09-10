#!/bin/bash
set -euo pipefail

while true; do
    # Only write to console when no users are logged in.
    if [ -z "$(who)" ]; then
        echo "EMC-TEST" > /dev/console
    fi
    sleep 1
done
