#!/bin/bash
set -euo pipefail

modprobe btnxpuart

while true; do
    hcitool scan
done

exit 1
