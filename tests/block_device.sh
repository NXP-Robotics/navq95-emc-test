#!/bin/bash
set -euo pipefail

mkdir -p /mnt/$1
mount /dev/$1 /mnt/$1

while true; do
    dd if=/dev/zero of=/mnt/$1/testfile bs=4M count=32 oflag=direct
    sync
    dd if=/mnt/$1/testfile of=/dev/null bs=4M iflag=direct
done
