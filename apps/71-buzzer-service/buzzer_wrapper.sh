#!/bin/sh
read L
FREQ=$(echo $L | cut -d' ' -f1)
DUR=$(echo $L | cut -d' ' -f2)
sh /useremain/home/rinkhals/apps/71-buzzer-service/buzzer.sh $FREQ $DUR