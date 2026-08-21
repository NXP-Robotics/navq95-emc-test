#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SERVICES_DIR=$SCRIPT_DIR/services
SERVICES=$(ls "$SERVICES_DIR")

# Install required packages
apt-get update -y
apt-get install -yq alsa-utils can-utils

# Copy contents to /opt/navq95-emc
mkdir -p /opt/navq95-emc
rsync -a --delete ./* /opt/navq95-emc/

# Create services and enable them
cp $SERVICES_DIR/* /usr/lib/systemd/system
systemctl enable bluetooth $SERVICES

sync
