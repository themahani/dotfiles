#!/usr/bin/env bash

bat_cap=""
ac_online="0"

for supply in /sys/class/power_supply/*; do
    type="$(cat "$supply/type" 2>/dev/null)"
    case "$type" in
        Battery)
            cap="$(cat "$supply/capacity" 2>/dev/null)"
            [ -n "$cap" ] && bat_cap="$cap%" && break
            ;;
        Mains)
            online="$(cat "$supply/online" 2>/dev/null)"
            [ "$online" = "1" ] && ac_online="1"
            ;;
    esac
done

icon=""
[ "$ac_online" = "1" ] && icon="⚡"

echo "${bat_cap} ${icon}"
