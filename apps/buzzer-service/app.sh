#!/bin/sh
APP_ROOT=$(dirname "$(readlink -f "$0")")
. /useremain/rinkhals/.current/tools.sh

# Ensure scripts are executable
chmod +x ${APP_ROOT}/buzzer.sh
chmod +x ${APP_ROOT}/buzzer_wrapper.sh

mkdir -p /tmp/rinkhals
LOG=/tmp/rinkhals/buzzer-service.log

wait_and_start() {
    echo "$(date): wait_and_start began" >> $LOG
    ATTEMPTS=0
    MAX_ATTEMPTS=60
    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        if ps | grep "ttyACM" | grep -v grep | grep -q socat; then
            echo "$(date): tunneled-klipper ready after ${ATTEMPTS} attempts" >> $LOG
            socat TCP-LISTEN:7777,fork,reuseaddr \
                EXEC:"/bin/sh ${APP_ROOT}/buzzer_wrapper.sh" \
                >> $LOG 2>&1 &
            echo "$(date): socat started PID $!" >> $LOG
            return 0
        fi
        sleep 2
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "$(date): attempt $ATTEMPTS - waiting for ttyACM..." >> $LOG
    done
    echo "$(date): timed out waiting for tunneled-klipper" >> $LOG
}

case "$1" in
    start)
        echo "$(date): app.sh start called" >> $LOG
        wait_and_start &
        ;;
    stop)
        kill $(ps | grep "TCP-LISTEN:7777" | grep -v grep | awk '{print $1}') 2>/dev/null
        echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/enable
        echo "$(date): app.sh stop called" >> $LOG
        ;;
    status)
        PIDS=$(get_pids socat)
        report_status "$PIDS"
        ;;
esac