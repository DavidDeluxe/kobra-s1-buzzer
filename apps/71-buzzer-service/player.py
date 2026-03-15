#!/usr/bin/env python3
import time
import sys
import re

PWM0 = "/sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0"

def pwm_write(file, value):
    try:
        with open(f"{PWM0}/{file}", "w") as f:
            f.write(str(value))
    except:
        pass

# Always reset PWM state before starting
pwm_write("enable", 0)
pwm_write("duty_cycle", 0)

def play(freq, dur):
    if freq <= 0:
        pwm_write("enable", 0)
        time.sleep(dur)
        return

    period = int(1_000_000_000 / freq)
    duty = period // 2

    pwm_write("enable", 0)
    pwm_write("duty_cycle", 0)
    pwm_write("period", period)
    pwm_write("duty_cycle", duty)
    pwm_write("enable", 1)

    time.sleep(dur)
    pwm_write("enable", 0)
    time.sleep(0.02)

def load_gcode(path):
    notes = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            m300 = re.match(r"M300\s*S(\d+)\s*P(\d+)|M300\s*P(\d+)\s*S(\d+)", line, re.IGNORECASE)
            if m300:
                if m300.group(1):
                    freq, dur = int(m300.group(1)), int(m300.group(2))
                else:
                    freq, dur = int(m300.group(4)), int(m300.group(3))
                notes.append((freq, dur / 1000))
            g4 = re.match(r"G4\s*P(\d+)", line, re.IGNORECASE)
            if g4:
                notes.append((0, int(g4.group(1)) / 1000))
    return notes

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: player.py <tune.gcode>")
        sys.exit(1)

    notes = load_gcode(sys.argv[1])

    for freq, dur in notes:
        play(freq, dur)

    pwm_write("enable", 0)
    pwm_write("duty_cycle", 0)