#!/bin/sh
APP_ROOT=$(dirname "$(readlink -f "$0")")
. /useremain/rinkhals/.current/tools.sh

case "$1" in
    start)
        socat TCP-LISTEN:7777,fork,reuseaddr \
            EXEC:"/bin/sh ${APP_ROOT}/buzzer_wrapper.sh" \
            >> /tmp/rinkhals/buzzer-server.log 2>&1 &
        ;;
    stop)
        kill $(ps | grep "TCP-LISTEN:7777" | grep -v grep | awk '{print $1}') 2>/dev/null
        echo 0 > /sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0/enable
        ;;
    status)
        PIDS=$(get_pids socat)
        report_status "$PIDS"
        ;;
esac