#!/bin/sh
APP_DIR="$(dirname "$(realpath "$0")")"
TUNES_DIR="${APP_DIR}/tunes"
PLAYER_PY="${APP_DIR}/player.py"
BUZZER_SH="${APP_DIR}/buzzer.sh"
PIDFILE="/tmp/buzzer_player.pid"

read L
COMMAND=$(echo $L | cut -d' ' -f1)
SECOND=$(echo $L | cut -d' ' -f2)

stop_tune() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        kill -9 "$PID" 2>/dev/null
        rm -f "$PIDFILE"
        usleep 200000
    fi
    # Ensure buzzer is turned off when stopping a tune
    echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/enable 2>/dev/null || true
    echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/duty_cycle 2>/dev/null || true
}

if [ "$SECOND" = "$COMMAND" ] || [ -z "$SECOND" ]; then
    TUNE_NAME=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

    if [ "$TUNE_NAME" = "stop" ]; then
        stop_tune
        exit 0
    fi

    if [ -f "${TUNES_DIR}/${TUNE_NAME}.py" ]; then
        stop_tune
        python3 "$PLAYER_PY" "${TUNES_DIR}/${TUNE_NAME}.py" &
        echo $! > "$PIDFILE"
    elif [ -f "${TUNES_DIR}/${TUNE_NAME}.gcode" ]; then
        stop_tune
        python3 "$PLAYER_PY" "${TUNES_DIR}/${TUNE_NAME}.gcode" &
        echo $! > "$PIDFILE"
    else
        echo "ERROR: No tune file found for '${TUNE_NAME}'" >&2
        exit 1
    fi
else
    sh "$BUZZER_SH" "$COMMAND" "$SECOND"
fi