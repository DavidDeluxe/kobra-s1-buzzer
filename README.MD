# Kobra S1 Buzzer Service

Native M300 buzzer support for the Anycubic Kobra S1 running vanilla Klipper
via [Rinkhals](https://github.com/jbatonnet/Rinkhals) and
[tunneled-klipper](https://github.com/Kobra-S1/vanilla-klipper-swu).

Drives the printer's built-in buzzer at `/sys/devices/platform/ff350000.pwm`
over a TCP socket, triggered by M300 gcode from Klipper running on a BTT Pi2
(or any external Klipper host).

## Requirements

- Anycubic Kobra S1 with Rinkhals installed
- Vanilla Klipper running on an external host (BTT Pi2 or similar) via tunneled-klipper
- Both printer and Klipper host on the same network

## Installation

### Option 1: SWU (recommended)

1. Download `71-buzzer-service.swu` from the [Releases](../../releases) page
2. Rename it to `update.swu`
3. Copy it to a FAT32 USB drive in a directory named `aGVscF9zb3Nf`
4. Plug the USB drive into the printer — it installs automatically
5. Enable the app via the Rinkhals touch UI or by rebooting

### Option 2: Manual (SSH/SFTP)

1. Connect to the printer via SSH or SFTP (user: `root`, password: `rockchip`)
2. Copy the `apps/71-buzzer-service/` directory to `/useremain/home/rinkhals/apps/` on the printer
3. Reboot or start manually:
```sh
   sh /useremain/home/rinkhals/apps/71-buzzer-service/app.sh start
```

## Klipper setup (on BTT Pi2 or external Klipper host)

1. Copy `klipper/buzzer.cfg` and `klipper/buzzer_tunes.cfg` to your Klipper
   config directory (e.g. `~/printer_data/config/`)

2. Edit `buzzer.cfg` and replace `PRINTER_IP` with your printer's IP address

3. Add to your `printer.cfg`:
```ini
   [include buzzer.cfg]
```

4. Restart Klipper

5. Test from the Mainsail/Fluidd console:
```
   M300 S1000 P500
```

## Usage

### M300 syntax
```
M300 S<frequency_hz> P<duration_ms>
```

- `S` — frequency in Hz (0 = silence)
- `P` — duration in milliseconds

### Built-in tune macros

| Macro | Description |
|---|---|
| `TUNE_PRINT_DONE` | Play on print complete |
| `TUNE_PRINT_FAILED` | Play on print failure |
| `TUNE_BEEP` | Single short beep |
| `TUNE_READY` | Printer ready |

Add `TUNE_PRINT_DONE` to your `END_PRINT` macro and `TUNE_PRINT_FAILED` to
your `CANCEL_PRINT` macro.

## How it works

The buzzer service runs as a Rinkhals app on the printer's SoC. It listens on
TCP port 7777 for `FREQ MS` commands and drives the PWM buzzer directly via
`/sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0`.

Klipper uses `gcode_shell_command` to send each M300 tone over the network via
`socat`, which is already present on both hosts as part of the tunneled-klipper
setup.

## Credits

- [Rinkhals](https://github.com/jbatonnet/Rinkhals) by jbatonnet
- [vanilla-klipper-swu / tunneled-klipper](https://github.com/Kobra-S1/vanilla-klipper-swu)