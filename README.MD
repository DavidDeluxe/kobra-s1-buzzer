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

- `S` — frequency in Hz (default: 1000). Use `S0` for silence.
- `P` — duration in milliseconds (default: 100)

### How tones work

Each `M300` call sends a frequency and duration to the buzzer server running
on the printer's SoC via TCP. Klipper uses `G4` to wait for each note to
finish before moving to the next, ensuring correct rhythm when chaining
multiple `M300` calls together.

### How tunes work

Long tunes like `TUNE_MARIO` use a non-blocking method — Klipper sends the
tune name to the printer and returns instantly. The printer looks up the tune
file by name in the `tunes/` directory and plays it entirely on its own SoC
using a Python player, so printing is never blocked during playback.

### Built-in tune macros

| Macro | Type | Description |
|---|---|---|
| `TUNE_PRINT_DONE` | Blocking | Play at end of print |
| `TUNE_PRINT_FAILED` | Blocking | Play on cancel/failure |
| `TUNE_BEEP` | Blocking | Single short beep |
| `TUNE_READY` | Blocking | Printer homed and ready |
| `TUNE_MARIO` | Non-blocking | Mario theme |

### Adding your own tunes

To add a new long tune:

1. Create `<name>.py` in `tunes/` on the printer with a `notes` array:
```python
notes = [
    (frequency_hz, duration_seconds),
    (660, 0.1),
    (0, 0.1),   # 0 Hz = silence
    ...
]
```
2. Add a macro to `buzzer_tunes.cfg` on the Pi2:
```ini
[gcode_macro TUNE_MYNAME]
description: My custom tune
gcode:
    PLAY_TUNE TUNE=myname
```
3. Restart Klipper — no changes needed to any other files.

### Suggested macro hooks

Add these to your existing macros in `printer.cfg`:
```ini
# In END_PRINT
TUNE_PRINT_DONE

# In CANCEL_PRINT
TUNE_PRINT_FAILED

# In START_PRINT (after homing)
TUNE_READY
```

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