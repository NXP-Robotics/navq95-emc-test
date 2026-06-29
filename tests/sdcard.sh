#!/bin/bash
set -euo pipefail

while true; do
    dd if=/dev/zero of=/testfile bs=4M count=32 oflag=direct
    sync
    dd if=/testfile of=/dev/null bs=4M iflag=direct
done
