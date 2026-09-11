# WLAN RF Test - Continuous Transmission (NXP `wlan_sdio`)

Run continuous TX on an NXP Wi-Fi module (`mlan0`) with different CHANNEL,
MODE, BANDWIDTH and POWER using `navq95-emc-test/control/wifi.sh`. The
script drives RF test mode via `/proc/mwlan/adapter0/config`, brings `mlan0`
down first (required for RF test mode) and back up when stopped.

> RF test mode is for lab/EMC testing only; normal Wi-Fi is disabled while active.

## Parameters

| Flag | Parameter | Values |
|------|-----------|--------|
| `-c` | CHANNEL   | 1-14 (2.4 GHz), 36/40/44/48/149... (5 GHz) |
| `-m` | MODE      | `radio_mode` value, e.g. 11 = 2.4G [1x1], 3 = 5G [1x1] |
| `-b` | BANDWIDTH | 0 = 20 MHz, 1 = 40 MHz, 4 = 80 MHz |
| `-p` | POWER     | TX power in dBm, 0-24 (chip/caldata dependent) |
| `-d` | DURATION  | seconds, then auto-stop (optional) |

## Usage

```bash
# first stop automatic EMC test system utilisation
sudo ~/navq95-emc-test/stop.sh

# Run for a fixed duration (channel 6, 2.4G 1x1, 20 MHz, 15 dBm, 30 s)
sudo ~/navq95-emc-test/control/wifi.sh -c 6 -m 11 -b 0 -p 15 -d 30

# Run until stopped manually (channel 36, 5G 1x1, 80 MHz, 12 dBm)
sudo ~/navq95-emc-test/control/wifi.sh -c 36 -m 3 -b 4 -p 12
sudo ~/navq95-emc-test/control/wifi.sh --stop
```

Re-run with new values to test other combinations. Use `--help` for options.

## Notes

- Run with `sudo`; requires the `wlan_sdio` driver loaded and `mlan0` present.
- POWER must be 0-24 dBm. Negative values are rejected by the firmware on
  these chips ("RF test mode cmd error").
- `tx_power` is only applied if calibration data is loaded; if it reads back
  empty in the config file, caldata is missing.
- Inspect current state anytime: `cat /proc/mwlan/adapter0/config`.
