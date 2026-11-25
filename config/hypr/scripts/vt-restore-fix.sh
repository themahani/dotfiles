#!/usr/bin/env bash
# Work around Hyprland's screen staying black or frozen after a VT switch on the
# NVIDIA 580 driver. When Hyprland gets the display back, aquamarine commits the
# framebuffer it had before the switch, nvidia-drm rejects it with EINVAL, and
# the log shows "crtc N failed restore". Suspend triggers the same failure
# because nvidia-sleep.sh switches to VT 63 before sleeping and back after.
#
# The driver accepts new buffers, and a mode change makes aquamarine allocate
# them. This script waits for this Hyprland's login session to become active
# again, then switches each monitor to another resolution and back.
#
# The VT switch also leaves the session lock without keyboard focus, and
# Hyprland doesn't give it back. Suspend always switches VTs, because the
# kernel moves to VT 63 itself when the console framebuffer asks for it. When
# the session is locked, the script turns each monitor off and on instead.
# Quickshell then creates a new lock surface, and Hyprland focuses it. This
# also allocates new buffers.
#
# Start it from Hyprland's autostart (autostart_extra in hypr.local.lua).

set -u

session=${XDG_SESSION_ID:?XDG_SESSION_ID is not set}
path=$(busctl --system call org.freedesktop.login1 /org/freedesktop/login1 \
	org.freedesktop.login1.Manager GetSession s "$session" | awk '{print $2}' | tr -d '"')
[ -n "$path" ] || exit 1

log() { logger -t vt-restore-fix "$*"; }

is_active() {
	loginctl show-session "$session" -p Active --value 2>/dev/null
}

refresh_monitors() {
	hyprctl -j monitors | jq -c '.[]' | while read -r mon; do
		name=$(jq -r '.name' <<<"$mon")
		size=$(jq -r '"\(.width)x\(.height)"' <<<"$mon")
		mode=$(jq -r '"\(.width)x\(.height)@\(.refreshRate)"' <<<"$mon")
		position=$(jq -r '"\(.x)x\(.y)"' <<<"$mon")
		scale=$(jq -r '.scale' <<<"$mon")
		# Any mode with a different size forces new buffers.
		temp=$(jq -r --arg size "$size" \
			'[.availableModes[] | select(startswith($size + "@") | not)][0] // empty | sub("Hz$"; "")' <<<"$mon")
		if [ -z "$temp" ]; then
			log "$name: no other mode to switch to, skipping"
			continue
		fi
		log "$name: switching to $temp and back to $mode"
		hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$temp\", position = \"$position\", scale = $scale })" >/dev/null
		sleep 1
		hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"$position\", scale = $scale })" >/dev/null
	done
}

is_locked() {
	loginctl show-session "$session" -p LockedHint --value 2>/dev/null
}

cycle_monitors() {
	hyprctl -j monitors | jq -c '.[]' | while read -r mon; do
		name=$(jq -r '.name' <<<"$mon")
		mode=$(jq -r '"\(.width)x\(.height)@\(.refreshRate)"' <<<"$mon")
		position=$(jq -r '"\(.x)x\(.y)"' <<<"$mon")
		scale=$(jq -r '.scale' <<<"$mon")
		log "$name: turning off and on at $mode"
		hyprctl eval "hl.monitor({ output = \"$name\", disabled = true })" >/dev/null
		sleep 1
		hyprctl eval "hl.monitor({ output = \"$name\", disabled = false, mode = \"$mode\", position = \"$position\", scale = $scale })" >/dev/null
	done
}

was_active=$(is_active)
gdbus monitor --system --dest org.freedesktop.login1 --object-path "$path" | while read -r _; do
	now=$(is_active)
	# The session is gone after logout, so stop.
	[ -n "$now" ] || exit 0
	if [ "$was_active" = no ] && [ "$now" = yes ]; then
		# Let aquamarine's own restore run (and fail) first.
		sleep 1
		if [ "$(is_locked)" = yes ]; then
			cycle_monitors
		else
			refresh_monitors
		fi
	fi
	was_active=$now
done
