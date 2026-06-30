#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SERVICES_DIR=$SCRIPT_DIR/services
SERVICES=$(ls "$SERVICES_DIR")

systemctl stop $SERVICES || true
