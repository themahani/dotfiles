#!/bin/bash

# Directory containing your wallpapers
WALLPAPER_DIR="$HOME/.wallpapers"
ROFI_CONFIG_DIR="$HOME/.config/rofi"
CURRENT_WALLPAPER="$WALLPAPER_DIR/.current"

# Collect wallpapers NUL-delimited (safe for spaces/newlines), sorted for stable indices
mapfile -d '' WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | sort -z)

# Check if there are any wallpapers
if [ "${#WALLPAPERS[@]}" -eq 0 ]; then
    rofi -e "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Show basenames only; resolve the choice via index so nested dirs
# (and duplicate basenames) keep working. -format i prints the
# original input index (0-based), unaffected by user filtering.
SELECTED_INDEX=$(
    for wallpaper in "${WALLPAPERS[@]}"; do
        printf '%s\0icon\x1f%s\n' "$(basename "$wallpaper")" "$wallpaper"
    done | rofi -dmenu -i -show-icons -format i -theme "$ROFI_CONFIG_DIR/config-wallpaper.rasi"
)

# Empty / non-numeric output means the user cancelled
if [[ ! "$SELECTED_INDEX" =~ ^[0-9]+$ ]]; then
    exit 0
fi

SELECTED_WALLPAPER="${WALLPAPERS[$SELECTED_INDEX]}"

load_wallpaper() {
    local new_wallpaper="$1"
    local old_wallpaper=""

    # Remember the previously applied wallpaper so we can unload it
    if [ -L "$CURRENT_WALLPAPER" ]; then
        old_wallpaper="$(readlink "$CURRENT_WALLPAPER")"
    fi

    ln -sf "$new_wallpaper" "$CURRENT_WALLPAPER"   # Create symlink

    # Start hyprpaper if it isn't running (fresh instances pick up .current via hyprpaper.conf)
    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
        hyprpaper >/dev/null 2>&1 &
        disown 2>/dev/null || true
        # Wait for hyprpaper IPC to come up
        for _ in {1..20}; do
            hyprctl hyprpaper listloaded >/dev/null 2>&1 && break
            sleep 0.25
        done
    fi

    # Live-switch via IPC: preload into memory, then apply to all monitors (empty monitor + comma)
    hyprctl hyprpaper preload "$new_wallpaper"
    hyprctl hyprpaper wallpaper ",$new_wallpaper"

    # Free the previous wallpaper from memory (best-effort)
    if [ -n "$old_wallpaper" ] && [ "$old_wallpaper" != "$new_wallpaper" ]; then
        hyprctl hyprpaper unload "$old_wallpaper" 2>/dev/null || true
    fi
}

# If a wallpaper was selected, point the symlink at it and apply via hyprctl
if [ -n "$SELECTED_WALLPAPER" ] && [ -f "$SELECTED_WALLPAPER" ]; then
    load_wallpaper "$SELECTED_WALLPAPER"
fi
