#!/bin/sh
. /useremain/rinkhals/.current/tools.sh

export APP_ROOT="$(dirname "$(realpath "$0")")"
export APP_NAME="$(basename "$APP_ROOT")"

mkdir -p $RINKHALS_LOGS
LOG=$RINKHALS_LOGS/buzzer-service.log
PID_FILE=/tmp/rinkhals/buzzer-service.pid

status() {
    PIDS=$(get_by_name "TCP-LISTEN:7777")
    if [ "$PIDS" = "" ]; then
        report_status $APP_STATUS_STOPPED "" $LOG
    else
        if [ -f "$PID_FILE" ]; then
            PIDS=$(cat "$PID_FILE")
        fi
        report_status $APP_STATUS_STARTED "$PIDS" $LOG
    fi
}

start() {
    cd "$APP_ROOT"

    # Ensure scripts are executable
    chmod +x ${APP_ROOT}/buzzer.sh
    chmod +x ${APP_ROOT}/buzzer_wrapper.sh

    echo "$(date): buzzer-service start called" >> $LOG

    PIDS=$(get_by_name "TCP-LISTEN:7777")
    if [ "$PIDS" != "" ]; then
        echo "$(date): already running, skipping start" >> $LOG
        return 0
    fi

    # Wait for network and other services to be ready
    sleep 5

    echo "$(date): starting socat listener" >> $LOG
    socat TCP-LISTEN:7777,fork,reuseaddr \
        EXEC:"/bin/sh ${APP_ROOT}/buzzer_wrapper.sh" \
        >> $LOG 2>&1 &

    echo $! > $PID_FILE
    echo "$(date): socat started PID $!" >> $LOG
}

stop() {
    echo "$(date): buzzer-service stop called" >> $LOG
    kill_by_port 7777
    rm -f $PID_FILE
    echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/enable
    echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/duty_cycle
    echo "$(date): buzzer-service stopped" >> $LOG
}

case "$1" in
    status)
        status
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        echo "Usage: $0 {status|start|stop}" >&2
        exit 1
        ;;
esac