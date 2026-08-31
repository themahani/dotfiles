#!/bin/bash

CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity)
AC_ONLINE=$(cat /sys/class/power_supply/AC/online)

if [ "$AC_ONLINE" = "1" ]; then
    echo "${CAPACITY}% ⚡"
else
    echo "${CAPACITY}%   "
fi
