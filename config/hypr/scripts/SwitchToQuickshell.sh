#!/usr/bin/env bash
# Switch this session from Waybar/SwayNC to the desktop Quickshell config.
set -euo pipefail

command -v quickshell >/dev/null || { echo "quickshell is not installed" >&2; exit 1; }

script_dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
source_dir=$(realpath -- "$script_dir/../../quickshell")
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop"

if [[ ! -e "$config_dir" && ! -L "$config_dir" ]]; then
    mkdir -p -- "$(dirname -- "$config_dir")"
    ln -s -- "$source_dir" "$config_dir"
fi
[[ -f "$config_dir/shell.qml" ]] || { echo "Missing config: $config_dir/shell.qml" >&2; exit 1; }

# Stop the user service too, so it cannot restart the notification daemon.
systemctl --user stop swaync.service 2>/dev/null || true
for process in waybar swaync; do
    pkill -u "$(id -u)" -x "$process" || true
done

# Allow SwayNC to release its notification-server D-Bus name.
for ((attempt = 0; attempt < 30; attempt++)); do
    pgrep -u "$(id -u)" -x swaync >/dev/null || break
    sleep 0.1
done
if pgrep -u "$(id -u)" -x swaync >/dev/null; then
    echo "SwayNC is still running; stop it before starting Quickshell." >&2
    exit 1
fi

quickshell -c desktop --daemonize --no-duplicate
