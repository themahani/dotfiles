#!/bin/bash

# Directory containing your wallpapers
WALLPAPER_DIR="$HOME/.wallpapers/"
ROFI_CONFIG_DIR="$HOME/.config/rofi"

# Get a list of all image files in the directory
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" ))

# Check if there are any wallpapers
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    rofi -e "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Create a rofi menu with wallpaper previews
MENU=""
for wallpaper in "${WALLPAPERS[@]}"; do
    MENU+="$(basename "$wallpaper")\0icon\x1f$wallpaper\n"
done

# Show the rofi menu and get the selected wallpaper
SELECTION=$(echo -en "$MENU" | rofi -dmenu -i -show-icons -theme "$ROFI_CONFIG_DIR/config-wallpaper.rasi")

# If a wallpaper was selected, set it with swww
if [ -n "$SELECTION" ]; then
    SELECTED_WALLPAPER="$WALLPAPER_DIR$SELECTION"
    swww img "$SELECTED_WALLPAPER" --transition-type any --transition-fps 60
fi
