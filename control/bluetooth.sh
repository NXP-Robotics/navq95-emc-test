#!/bin/bash
#
# bluetooth_control.sh - Put an NXP IW61x (IW612) Bluetooth radio (btnxpuart)
# into RF test mode for continuous transmission on a selected channel/power.
#
# See bluetooth_rf_test_continuous_tx.md for full documentation, parameter
# reference, channel numbering and usage examples. Run with --help for options.

set -u


MODULE="btnxpuart"

HCI=""          # e.g. hci0; auto-detected if empty
CHANNEL=""
MODE="ble"      # ble | cw
POWER=""        # dBm; applied via NXP vendor set-power command (optional)
LENGTH=37       # test payload length in bytes (0..37 per spec)
PKT=0           # LE test packet payload type (see -k help)
DURATION=""     # seconds; if empty, TX runs until stopped manually
STOP_ONLY=0

# LE DTM channel range (spec): 0..39
CHANNEL_MIN=0
CHANNEL_MAX=39

# Practical TX power range in dBm for the vendor set-power command.
POWER_MIN=-20
POWER_MAX=20

# --- NXP vendor-specific HCI command encodings -------------------------------
# These are firmware dependent. Override here if your IW61x firmware differs.
#
# hcitool cmd takes: <ogf> <ocf> [parameters...]  (all in hex)
# Vendor commands use OGF 0x3F.
#
# Set TX power (vendor). IW61x NXP vendor command, confirmed by AN14114
# (RF Test Mode on Linux) and the edgefast Bluetooth stack source:
#   full HCI opcode 0xFC87 -> OGF 0x3F, OCF 0x087
#   (BT_HCI_OP_LE_SET_TX_POWER / HCI_CMD_BLE_WRITE_TRANSMIT_POWER_LEVEL)
# Parameter: <power_signed_byte> in dBm.
VS_SET_POWER_OGF=0x3F
VS_SET_POWER_OCF=0x0087
VS_SET_POWER_ENABLE=1       # 1 = apply vendor set-power; 0 = rely on caldata default


# Continuous wave / unmodulated carrier (vendor).
# Parameter layout assumed: <enable> <channel>.
VS_CW_OGF=0x3F
VS_CW_OCF=0x0000            # <-- set to your firmware's CW-test OCF
VS_CW_ENABLE=0              # 0 = vendor CW opcode unknown; see notes

usage() {
    cat <<EOF
Usage: $0 -c CHANNEL [-m MODE] [-p POWER] [-l LENGTH] [-k PKT] [-i hciN] [-d DURATION]
       $0 --stop

Options:
  -c CHANNEL     RF test channel index 0..39 (freq = 2402 + 2*CHANNEL MHz)
  -m MODE        Test mode: ble (LE DTM continuous TX, default) or cw (carrier)
  -p POWER       TX power in dBm ($POWER_MIN to $POWER_MAX), via NXP vendor cmd (optional)
  -l LENGTH      LE test payload length in bytes, 0..37 (default $LENGTH)
  -k PKT         LE test payload type (default $PKT):
                   0 = PRBS9
                   1 = 0x0F repeated (11110000)
                   2 = 0x55 repeated (10101010)
                   3 = PRBS15
  -i hciN        HCI device to use (default: auto-detect first controller)
  -d DURATION    Transmit for DURATION seconds then stop (optional)
      --stop     Stop the test and reset the controller, then exit
  -h, --help     Show this help
EOF
}

# --- parse arguments ---------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        -c) CHANNEL="$2"; shift 2 ;;
        -m) MODE="$2"; shift 2 ;;
        -p) POWER="$2"; shift 2 ;;
        -l) LENGTH="$2"; shift 2 ;;
        -k) PKT="$2"; shift 2 ;;
        -i) HCI="$2"; shift 2 ;;
        -d) DURATION="$2"; shift 2 ;;
        --stop) STOP_ONLY=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

# --- helpers -----------------------------------------------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

is_int() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

is_signed_int() {
    case "$1" in
        ''|'-') return 1 ;;
        -*) is_int "${1#-}" ;;
        *) is_int "$1" ;;
    esac
}

# Convert a decimal value to a 2-digit hex byte string (for hcitool cmd).
to_hex_byte() {
    printf '0x%02X' "$(( $1 & 0xFF ))"
}

detect_hci() {
    # Return the first HCI device name, e.g. hci0.
    hciconfig 2>/dev/null | awk -F: '/^hci[0-9]+/ {print $1; exit}'
}

hci_up() {
    echo "Bringing up $HCI..."
    hciconfig "$HCI" up 2>/dev/null || die "could not bring up $HCI"
}

hci_reset() {
    # HCI_Reset: OGF 0x03, OCF 0x0003
    hcitool -i "$HCI" cmd 0x03 0x0003 >/dev/null 2>&1 || true
}

le_test_end() {
    # LE Test End: OGF 0x08, OCF 0x001F
    hcitool -i "$HCI" cmd 0x08 0x001F >/dev/null 2>&1 || true
}

# --- preflight checks --------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "must be run as root (use sudo)"
command -v hciconfig >/dev/null 2>&1 || die "hciconfig not found (install bluez / bluez-hcidump)"
command -v hcitool  >/dev/null 2>&1 || die "hcitool not found (install bluez)"

echo "Ensuring $MODULE driver is loaded..."
modprobe "$MODULE" 2>/dev/null || echo "  (warning: could not modprobe $MODULE; may be built-in)"

# Give the HCI transport a moment to enumerate.
sleep 1

if [ -z "$HCI" ]; then
    HCI="$(detect_hci)"
    [ -n "$HCI" ] || die "no HCI controller found - is the IW61x BT interface up? (check 'hciconfig -a')"
fi
echo "Using HCI device: $HCI"

# --- stop mode ---------------------------------------------------------------
if [ "$STOP_ONLY" -eq 1 ]; then
    echo "Stopping any running RF test..."
    le_test_end
    hci_reset
    echo "Resetting controller $HCI..."
    hciconfig "$HCI" reset 2>/dev/null || true
    echo "Done."
    exit 0
fi

# --- validate required params ------------------------------------------------
[ -n "$CHANNEL" ] || { usage; die "CHANNEL (-c) is required"; }

is_int "$CHANNEL" || die "CHANNEL must be an integer"
[ "$CHANNEL" -ge "$CHANNEL_MIN" ] && [ "$CHANNEL" -le "$CHANNEL_MAX" ] \
    || die "CHANNEL must be between $CHANNEL_MIN and $CHANNEL_MAX (freq = 2402 + 2*CHANNEL MHz)"

is_int "$LENGTH" || die "LENGTH must be an integer"
[ "$LENGTH" -ge 0 ] && [ "$LENGTH" -le 37 ] || die "LENGTH must be between 0 and 37 bytes"

is_int "$PKT" || die "PKT must be an integer"
case "$PKT" in
    0|1|2|3) ;;
    *) die "PKT must be 0 (PRBS9), 1 (0x0F), 2 (0x55) or 3 (PRBS15)" ;;
esac

if [ -n "$POWER" ]; then
    is_signed_int "$POWER" || die "POWER must be an integer in dBm"
    [ "$POWER" -ge "$POWER_MIN" ] && [ "$POWER" -le "$POWER_MAX" ] \
        || die "POWER must be between $POWER_MIN and $POWER_MAX dBm"
fi

if [ -n "$DURATION" ]; then
    is_int "$DURATION" || die "DURATION must be an integer (seconds)"
fi

case "$MODE" in
    ble|cw) ;;
    *) die "MODE must be 'ble' (LE DTM) or 'cw' (continuous wave)" ;;
esac

FREQ_MHZ=$(( 2402 + 2 * CHANNEL ))

# --- configure and start -----------------------------------------------------
hci_up

# Stop anything that might already be running.
le_test_end
hci_reset

# Optional vendor TX power set.
if [ -n "$POWER" ]; then
    if [ "$VS_SET_POWER_ENABLE" -eq 1 ]; then
        echo "Setting TX power to ${POWER} dBm (vendor command)..."
        hcitool -i "$HCI" cmd "$VS_SET_POWER_OGF" "$VS_SET_POWER_OCF" \
            "$(to_hex_byte "$POWER")" >/dev/null \
            || echo "  (warning: vendor set-power command failed)"
    else
        echo "NOTE: -p POWER requested but the vendor set-power opcode is not"
        echo "      configured (VS_SET_POWER_ENABLE=0). TX power will follow the"
        echo "      module calibration default. Set VS_SET_POWER_OCF/ENABLE in"
        echo "      this script once you have the IW61x vendor opcode."
    fi
fi

echo
echo "Parameters: MODE=$MODE CHANNEL=$CHANNEL (${FREQ_MHZ} MHz) LENGTH=$LENGTH PKT=$PKT"
echo

if [ "$MODE" = "ble" ]; then
    echo "Starting LE DTM continuous transmission..."
    # LE Transmitter Test: OGF 0x08, OCF 0x001E
    #   param1: TX channel (0..39)
    #   param2: test data length (0..37)
    #   param3: packet payload type (0..3)
    hcitool -i "$HCI" cmd 0x08 0x001E \
        "$(to_hex_byte "$CHANNEL")" \
        "$(to_hex_byte "$LENGTH")" \
        "$(to_hex_byte "$PKT")" \
        || die "LE Transmitter Test command failed"
else
    echo "Starting continuous wave (carrier) transmission (vendor command)..."
    if [ "$VS_CW_ENABLE" -eq 1 ]; then
        # Vendor CW test: <enable=1> <channel>
        hcitool -i "$HCI" cmd "$VS_CW_OGF" "$VS_CW_OCF" \
            0x01 "$(to_hex_byte "$CHANNEL")" \
            || die "vendor CW command failed"
    else
        die "CW mode requires the IW61x vendor CW opcode. Set VS_CW_OCF and VS_CW_ENABLE=1 in this script, or use '-m ble'."
    fi
fi

echo
echo "Controller status:"
hciconfig "$HCI" 2>/dev/null || true
echo

if [ -n "$DURATION" ]; then
    echo "Transmitting for $DURATION second(s)..."
    sleep "$DURATION"
    echo "Stopping RF test..."
    le_test_end
    hci_reset
    echo "Resetting controller $HCI..."
    hciconfig "$HCI" reset 2>/dev/null || true
    echo "Done."
else
    echo "Continuous TX is running on ${FREQ_MHZ} MHz."
    echo "Stop it with:  sudo $0 --stop"
fi
