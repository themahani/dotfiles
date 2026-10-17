#!/usr/bin/env bash
# Battery label for hyprlock, using the quickshell bar's icons.

icons=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)

for supply in /sys/class/power_supply/*; do
    [ "$(cat "$supply/type" 2>/dev/null)" = "Battery" ] || continue
    cap="$(cat "$supply/capacity" 2>/dev/null)"
    [ -n "$cap" ] || continue
    case "$(cat "$supply/status" 2>/dev/null)" in
        Charging) icon="" ;;
        Full|"Not charging") icon="󱘖" ;;
        *) icon="${icons[$((cap >= 100 ? 10 : cap / 10))]}" ;;
    esac
    [ "$cap" -ge 100 ] && echo "$icon Full" || echo "$icon $cap%"
    exit
done
