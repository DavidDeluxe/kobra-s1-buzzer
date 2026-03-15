# Kobra S1 Buzzer Service

Native M300 buzzer support for the Anycubic Kobra S1 running vanilla Klipper
via [Rinkhals](https://github.com/jbatonnet/Rinkhals) and
[tunneled-klipper](https://github.com/Kobra-S1/vanilla-klipper-swu).

Drives the printer's built-in buzzer at `/sys/devices/platform/ff350000.pwm`
over a TCP socket, triggered by M300 gcode from Klipper running on a RPi4/5, BTT Pi2
(or any external Klipper host).

## Requirements

- Anycubic Kobra S1 with Rinkhals installed
- Vanilla Klipper running on an external host (RPi 4/5, BTT Pi2 or similar) via tunneled-klipper
- Both printer and Klipper host on the same network

## Installation

### Option 1: SWU (recommended)

1. Download `update.swu` from the [Releases](../../releases) page
2. Make sure it's named as `update.swu`
3. Copy it to a FAT32 USB drive in a directory named `aGVscF9zb3Nf`
4. Plug the USB drive into the printer — it installs automatically in a few seconds
5. Enable the app via the Rinkhals touch UI or by rebooting. Service shouls start automatically.

### Option 2: Manual (SSH/SFTP)

1. Connect to the printer via SSH or SFTP (user: `root`, password: `rockchip`)
2. Copy the `apps/buzzer-service/` directory to `/useremain/home/rinkhals/apps/` on the printer
3. Reboot or start manually:
```sh
   sh /useremain/home/rinkhals/apps/buzzer-service/app.sh start
```

## Klipper Setup (on RPi4/5, BTT Pi2 or other Klipper host)

1. Copy `klipper/buzzer.cfg` to your Klipper config directory (e.g. `~/printer_data/config/`)
2. Edit `buzzer.cfg` and replace `[PRINTER_IP]` with your printer's IP (not Klipper host) address
   in all 3 `gcode_shell_command` blocks (buzzer_simple_beep, buzzer_tune, buzzer_stop)
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

Long tunes use a non-blocking method — Klipper sends the tune name to the
printer and returns instantly. The printer looks up the tune file by name in
the `tunes/` directory and plays it entirely on its own SoC using a Python
player, so printing is never blocked during playback.

### Built-in tune macros

| Macro | Type | Description |
|---|---|---|
| `TUNE_PRINT_DONE` | Blocking | Play at end of print |
| `TUNE_PRINT_FAILED` | Blocking | Play on cancel/failure |
| `TUNE_BEEP` | Blocking | Single short beep |
| `TUNE_READY` | Blocking | Printer homed and ready |
| `TUNE_MARIO` | Non-blocking | Mario theme |
| `STOP_TUNE` | — | Stop any currently playing tune |

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

---

## Adding Custom Tunes

### Step 1: Get a MIDI file

Download MIDI files from [BitMidi](https://bitmidi.com/) — it has a large
free library of songs in MIDI format.

### Step 2: Convert MIDI to M300 gcode

Use the [MIDI to M300 Converter](https://www.layerfused.com/MIDI-M300) to
convert your MIDI file to M300 gcode commands. Leave all settings at their
defaults and copy the output to a new `.gcode` file.

### Step 3: Copy to the printer

Copy the new `.gcode` file to the `tunes/` directory on the printer via
SSH/SFTP (MobaXterm):
```
/useremain/home/rinkhals/apps/71-buzzer-service/tunes/mysong.gcode
```

### Step 4: Add a Klipper macro

Add to the end of`buzzer.cfg` on your klipper host:
```ini
[gcode_macro TUNE_MYSONG]
description: Play my custom song
gcode:
    PLAY_TUNE TUNE=mysong
```

### Step 5: Restart Klipper

That's it — no other files need to be changed. Call `TUNE_MYSONG` from the
Mainsail console to play it.

---

## How it works

The buzzer service runs as a Rinkhals app on the printer's SoC. It listens on
TCP port 7777 for commands and drives the PWM buzzer directly via
`/sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0`.

Two types of commands are supported:

- **`FREQ DUR`** — plays a single tone at the given frequency (Hz) and
  duration (ms). Used by M300 for short blocking tones.
- **`TUNENAME`** — looks up `tunes/<tunename>.gcode` on the printer and plays
  it non-blocking via a Python player.

Klipper uses `gcode_shell_command` to send commands over the network via
`socat`, which is already present on both hosts as part of the
tunneled-klipper setup.

## Resource Usage

The buzzer service is extremely lightweight on the Kobra S1 SoC:

- **Idle**: ~3.8MB RAM, 0% CPU
- **During a beep**: brief spike while the shell executes, immediately returns to idle
- **During a tune**: Python player uses ~6MB RAM for the duration of the tune

This is comparable to the existing socat tunnel processes and has no
measurable impact on print performance.

## Credits

- [Rinkhals](https://github.com/jbatonnet/Rinkhals) by jbatonnet
- [vanilla-klipper-swu / tunneled-klipper](https://github.com/Kobra-S1/vanilla-klipper-swu)
- [BitMidi](https://bitmidi.com/) — MIDI file library
- [MIDI to M300 Converter](https://www.layerfused.com/MIDI-M300) by LayerFused
