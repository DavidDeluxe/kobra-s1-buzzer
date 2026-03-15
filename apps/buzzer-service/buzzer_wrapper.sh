#!/bin/sh
read L
COMMAND=$(echo $L | cut -d' ' -f1)
TUNES_DIR=/useremain/home/rinkhals/apps/buzzer-service/tunes
SECOND=$(echo $L | cut -d' ' -f2)
PIDFILE=/tmp/buzzer_player.pid

stop_tune() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat $PIDFILE)
        kill -9 $PID 2>/dev/null
        rm -f $PIDFILE
        usleep 200000
    fi
    echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/enable
    echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/duty_cycle
}

if [ "$SECOND" = "$COMMAND" ] || [ -z "$SECOND" ]; then
    TUNE_NAME=$(echo $COMMAND | tr '[:upper:]' '[:lower:]')

    if [ "$TUNE_NAME" = "stop" ]; then
        stop_tune
        exit 0
    fi

    if [ -f "${TUNES_DIR}/${TUNE_NAME}.py" ]; then
        stop_tune
        python3 /useremain/home/rinkhals/apps/buzzer-service/player.py ${TUNES_DIR}/${TUNE_NAME}.py &
        echo $! > $PIDFILE
    elif [ -f "${TUNES_DIR}/${TUNE_NAME}.gcode" ]; then
        stop_tune
        python3 /useremain/home/rinkhals/apps/buzzer-service/player.py ${TUNES_DIR}/${TUNE_NAME}.gcode &
        echo $! > $PIDFILE
    else
        echo "ERROR: No tune file found for '${TUNE_NAME}'" >&2
        exit 1
    fi
else
    sh /useremain/home/rinkhals/apps/buzzer-service/buzzer.sh $COMMAND $SECOND
fi