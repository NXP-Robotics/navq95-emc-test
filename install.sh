#!/bin/bash
set -euo pipefail

systemctl stop $(ls services) || true

cp services/* /usr/lib/systemd/system

systemctl enable $(ls services)
systemctl start $(ls services)

sync