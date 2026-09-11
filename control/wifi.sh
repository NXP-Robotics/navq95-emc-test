#!/bin/bash
#
# wifi_control.sh - Configure NXP wlan_sdio module (mlan0) for RF test mode
# continuous transmission with the given CHANNEL, MODE, BANDWIDTH and POWER.
#
# All control is done via the driver proc (manufacturing/RF test) interface:
#   /proc/mwlan/adapter0/config
#
# The proc keys used here match the NXP mwifiex driver (moal_proc.c):
#   rf_test_mode, radio_mode, channel, band, bw, tx_power, tx_continuous
#
# Usage:
#   sudo ./wifi_control.sh -c CHANNEL -m MODE -b BANDWIDTH -p POWER [-d DURATION]
#   sudo ./wifi_control.sh --stop
#
# Example:
#   sudo ./wifi_control.sh -c 6 -m 1 -b 0 -p 15 -d 30


set -u

IFACE="mlan0"
CFG="/proc/mwlan/adapter0/config"

CHANNEL=""
MODE=""
BANDWIDTH=""
POWER=""
DURATION=""     # seconds; if empty, TX runs until stopped manually
STOP_ONLY=0

# tx_power extra fields: <modulation> <path_id>
#   modulation: 0=CCK, 1=OFDM, 2=MCS   path_id: 0=PathA, 1=PathB, 2=PathA+B
TX_POWER_MOD=1
TX_POWER_PATH=0

# Practical TX power range in dBm accepted by the driver on these cards.
# NOTE: although the firmware nominally allows down to -15 dBm, on chips that
# use the 1/16 dBm conversion (9098/9097/9177/IW6xx/AW693) the driver rejects
# negative values (they encode above the 24 dBm / 384-unit limit and return
# "RF test mode cmd error"). Keep POWER within 0..24 dBm to be safe.
POWER_MIN=0
POWER_MAX=24

# tx_continuous extra fields:
#   <cw_mode> <payload_pattern> <cs_mode> <active_sub_ch> <tx_rate>
TX_CONT_CW_MODE=0
TX_CONT_PAYLOAD="0xAAAAAAAA"
TX_CONT_CS_MODE=0
TX_CONT_ACT_SUB_CH=0
TX_CONT_TX_RATE=7


usage() {
    cat <<EOF
Usage: $0 -c CHANNEL -m MODE -b BANDWIDTH -p POWER [-d DURATION]
       $0 --stop

Options:
  -c CHANNEL     RF channel number (2.4GHz: 1-14, 5GHz: 36,40,44,48,149,...)
  -m MODE        Radio mode value (radio_mode0), e.g. 11=2.4G[1x1], 3=5G[1x1]
  -b BANDWIDTH   Channel bandwidth: 0=20MHz 1=40MHz 4=80MHz
  -p POWER       TX power in dBm (0 to 24; chip/caldata dependent)
  -d DURATION    Transmit for DURATION seconds then stop (optional)
      --stop     Stop continuous TX and disable RF test mode, then exit
  -h, --help     Show this help
EOF
}

# --- parse arguments ---------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        -c) CHANNEL="$2"; shift 2 ;;
        -m) MODE="$2"; shift 2 ;;
        -b) BANDWIDTH="$2"; shift 2 ;;
        -p) POWER="$2"; shift 2 ;;
        -d) DURATION="$2"; shift 2 ;;
        --stop) STOP_ONLY=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

# --- helpers -----------------------------------------------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

cfg_write() {
    # cfg_write "key=value"
    echo "$1" > "$CFG" || die "failed to write '$1' to $CFG"
    echo "  wrote: $1"
}

is_int() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

# --- preflight checks --------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "must be run as root (use sudo)"
[ -e "$CFG" ] || die "$CFG not found - is the wlan_sdio driver loaded?"

# --- stop mode ---------------------------------------------------------------
if [ "$STOP_ONLY" -eq 1 ]; then
    echo "Stopping continuous TX and disabling RF test mode..."
    cfg_write "tx_continuous=0"
    cfg_write "rf_test_mode=0"
    echo "Bringing interface $IFACE back up..."
    ip link set "$IFACE" up 2>/dev/null || echo "  (warning: could not bring up $IFACE)"
    echo "Done."
    exit 0
fi

# --- validate required params ------------------------------------------------
[ -n "$CHANNEL" ]   || { usage; die "CHANNEL (-c) is required"; }
[ -n "$MODE" ]      || { usage; die "MODE (-m) is required"; }
[ -n "$BANDWIDTH" ] || { usage; die "BANDWIDTH (-b) is required"; }
[ -n "$POWER" ]     || { usage; die "POWER (-p) is required"; }

is_int "$CHANNEL"   || die "CHANNEL must be an integer"
is_int "$MODE"      || die "MODE must be an integer (radio_mode value)"
is_int "$BANDWIDTH" || die "BANDWIDTH must be an integer (0, 1 or 4)"
is_int "$POWER"     || die "POWER must be an integer in dBm"
[ "$POWER" -ge "$POWER_MIN" ] && [ "$POWER" -le "$POWER_MAX" ] \
    || die "POWER must be between $POWER_MIN and $POWER_MAX dBm (negative values are rejected by the firmware on these cards)"

case "$BANDWIDTH" in
    0|1|4) ;;
    *) die "BANDWIDTH must be 0 (20MHz), 1 (40MHz) or 4 (80MHz)" ;;
esac

if [ -n "$DURATION" ]; then
    is_int "$DURATION" || die "DURATION must be an integer (seconds)"
fi

# --- configure and start -----------------------------------------------------
echo "Bringing down interface $IFACE (required to access RF test mode)..."
ip link set "$IFACE" down 2>/dev/null || echo "  (warning: could not bring down $IFACE)"

echo "Enabling RF test mode..."
cfg_write "rf_test_mode=1"

# Select band automatically from the channel (0 = 2.4 GHz, 1 = 5 GHz).
if [ "$CHANNEL" -le 14 ]; then
    BAND=0
else
    BAND=1
fi

echo "Applying parameters (CHANNEL=$CHANNEL MODE=$MODE BANDWIDTH=$BANDWIDTH POWER=$POWER)..."
# radio_mode: MODE index for the requested rate/PHY
cfg_write "radio_mode=$MODE"
# band: 0 = 2.4 GHz, 1 = 5 GHz (derived from channel)
cfg_write "band=$BAND"
# channel: RF channel number
cfg_write "channel=$CHANNEL"
# bw: 0=20MHz 1=40MHz 4=80MHz
cfg_write "bw=$BANDWIDTH"
# tx_power: <power_dBm> <modulation> <path_id>
cfg_write "tx_power=$POWER $TX_POWER_MOD $TX_POWER_PATH"

echo "Starting continuous transmission..."
# tx_continuous: <enable> <cw_mode> <payload_pattern> <cs_mode> <act_sub_ch> <tx_rate>
cfg_write "tx_continuous=1 $TX_CONT_CW_MODE $TX_CONT_PAYLOAD $TX_CONT_CS_MODE $TX_CONT_ACT_SUB_CH $TX_CONT_TX_RATE"

echo
echo "Current config:"
cat "$CFG"
echo

if [ -n "$DURATION" ]; then
    echo "Transmitting for $DURATION second(s)..."
    sleep "$DURATION"
    echo "Stopping continuous TX and disabling RF test mode..."
    cfg_write "tx_continuous=0"
    cfg_write "rf_test_mode=0"
    echo "Bringing interface $IFACE back up..."
    ip link set "$IFACE" up 2>/dev/null || echo "  (warning: could not bring up $IFACE)"
    echo "Done."
else
    echo "Continuous TX is running."
    echo "Stop it with:  sudo $0 --stop"
fi
