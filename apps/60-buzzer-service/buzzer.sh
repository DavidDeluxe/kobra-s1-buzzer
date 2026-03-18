#!/bin/sh
FREQ=$1
DUR=$2
PWM_DIR=/sys/devices/platform/ff350000.pwm/pwm/pwmchip0/pwm0

echo 0 > $PWM_DIR/enable
echo 0 > $PWM_DIR/duty_cycle

if [ "$FREQ" -le 0 ]; then
    usleep $(awk "BEGIN{printf \"%d\",$DUR*1000}")
    exit 0
fi

PERIOD_NS=$(awk "BEGIN{printf \"%d\",1000000000/$FREQ}")
DUTY_NS=$(awk "BEGIN{printf \"%d\",$PERIOD_NS/2}")

echo $PERIOD_NS > $PWM_DIR/period
echo $DUTY_NS   > $PWM_DIR/duty_cycle
echo 1          > $PWM_DIR/enable

usleep $(awk "BEGIN{printf \"%d\",$DUR*1000}")

echo 0 > $PWM_DIR/enable
echo 0 > $PWM_DIR/duty_cycle