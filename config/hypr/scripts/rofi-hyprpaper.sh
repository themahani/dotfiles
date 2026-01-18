#!/bin/bash

# Directory containing your wallpapers
WALLPAPER_DIR="$HOME/.wallpapers"
ROFI_CONFIG_DIR="$HOME/.config/rofi"
CURRENT_WALLPAPER="$WALLPAPER_DIR/.current"

# Get a list of all image files in the directory
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f -name "*.jpg" -o -name "*.jpeg" -o -name "*.png"))

# Check if there are any wallpapers
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    rofi -e "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Create a rofi menu with wallpaper previews
MENU=""
for wallpaper in "${WALLPAPERS[@]}"; do
    MENU+="$(basename $wallpaper)\0icon\x1f$wallpaper\n"
done

# Show the rofi menu and get the selected wallpaper
SELECTION=$(echo -en "$MENU" | rofi -dmenu -i -show-icons -theme "$ROFI_CONFIG_DIR/config-wallpaper.rasi")

load_wallpaper() {
    killall hyprpaper && hyprpaper    # Make sure hyprpaper is active (can help fix crashes)
}

# If a wallpaper was selected, set it with swww
if [ -n "$SELECTION" ]; then
    SELECTED_WALLPAPER="$WALLPAPER_DIR/$SELECTION"
    ln -sf "$SELECTED_WALLPAPER" "$CURRENT_WALLPAPER"   # Create symlink
    load_wallpaper
fi
