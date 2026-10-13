-- Base keyboard, mouse, and startup applications.
---@type DotfilesHyprConfig
local config = {
  terminal = "kitty",
  file_manager = "nautilus",
  menu = "rofi -show drun",
  keyboard_layout = "us,ir",
  keyboard_options = "grp:win_space_toggle",
  mouse = { name = "epic-mouse-v1", sensitivity = -0.5 },
  autostart = {
    "hyprpaper", "quickshell -c desktop --no-duplicate", "hypridle", "hyprlauncher -d",
    "systemctl start --user hyprpolkitagent.service",
    "nm-applet --appindicator", "Telegram",
  },
}
return config
