#!/usr/bin/env bash
# Quickshell owns the brightness OSD, including while DND is enabled.
set -euo pipefail

case "${1:---get}" in
    --inc|--dec) quickshell -c desktop ipc call controls brightness "${1#--}" ;;
    --get) brightnessctl -m | cut -d, -f4 | tr -d '%' ;;
    *) printf 'Unknown brightness action: %s\n' "$1" >&2; exit 2 ;;
esac
