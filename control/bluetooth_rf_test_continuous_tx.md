# Bluetooth RF Test - Continuous Transmission (NXP IW61x / `btnxpuart`)

Run continuous TX on an NXP IW61x (IW612) Bluetooth radio with a selectable
channel and power using `navq95-emc-test/control/bluetooth.sh`. The script
drives RF test mode over the standard HCI interface via `hciconfig`/`hcitool`.

> RF test mode is for lab/EMC testing only; normal Bluetooth is disabled while active.

## Parameters

| Flag | Parameter | Values |
|------|-----------|--------|
| `-c` | CHANNEL   | 0-39 (freq = 2402 + 2*CHANNEL MHz; 0=2402, 19=2440, 39=2480) |
| `-m` | MODE      | `ble` = LE DTM continuous TX (default), `cw` = carrier |
| `-p` | POWER     | TX power in dBm, -20 to 20, via NXP vendor cmd (optional) |
| `-l` | LENGTH    | LE payload length in bytes, 0-37 (default 37) |
| `-k` | PKT       | LE payload type: 0=PRBS9, 1=0x0F, 2=0x55, 3=PRBS15 (default 0) |
| `-i` | hciN      | HCI device (default: auto-detect) |
| `-d` | DURATION  | seconds, then auto-stop (optional) |

## Usage

```bash
# first stop automatic EMC test system utilisation
sudo ~/navq95-emc-test/stop.sh

# LE DTM continuous TX on 2440 MHz for 30 s
sudo ~/navq95-emc-test/control/bluetooth.sh -c 19 -m ble -d 30

# Run until stopped manually (channel 0, 2402 MHz)
sudo ~/navq95-emc-test/control/bluetooth.sh -c 0 -m ble
sudo ~/navq95-emc-test/control/bluetooth.sh --stop
```

Use `--help` for options.

## Notes

- Run with `sudo`; requires the `btnxpuart` driver and an HCI controller
  (check `hciconfig -a`).
- Default `ble` mode is firmware independent (spec LE Transmitter Test / LE Test End).
- `-p POWER` uses the IW61x NXP vendor set-power command, HCI opcode `0xFC87`
  (OGF `0x3F`, OCF `0x087`), confirmed by AN14114 (RF Test Mode on Linux) and the
  edgefast Bluetooth stack; it is enabled by default in the script.
- `cw` mode still needs the IW61x vendor CW opcode: set `VS_CW_OCF` /
  `VS_CW_ENABLE` in the script, or use `-m ble`.

