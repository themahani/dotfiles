#!/usr/bin/env bash
# Shared entry point for compositor keys and other desktop scripts.
set -euo pipefail

case "${1:---get}" in
    --inc|--dec|--toggle)
        quickshell -c desktop ipc call controls volume "${1#--}"
        ;;
    --toggle-mic) quickshell -c desktop ipc call controls microphone toggle ;;
    --mic-inc) quickshell -c desktop ipc call controls microphone inc ;;
    --mic-dec) quickshell -c desktop ipc call controls microphone dec ;;
    --get) wpctl get-volume @DEFAULT_AUDIO_SINK@ ;;
    --get-icon) printf '%s\n' audio-volume-high ;;
    --get-mic-icon) printf '%s\n' audio-input-microphone ;;
    *) printf 'Unknown volume action: %s\n' "$1" >&2; exit 2 ;;
esac
