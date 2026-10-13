-- Copy to ~/.config/dotfiles/hypr.local.lua. All fields are optional.
-- Device names come from `hyprctl devices`; XKB layouts use comma-separated codes.
---@type DotfilesHyprConfig
local config = {
  keyboard_layout = "us",
  keyboard_options = "",
  mouse = false,
  -- Replace startup apps so personal apps do not start on your machine:
  autostart = { "quickshell -c desktop --no-duplicate", "hypridle" },
  -- autostart_extra = { "your-command" }, -- append to the base startup list
  -- terminal = "kitty",
  -- file_manager = "nautilus",
  -- menu = "rofi -show drun",
}
return config
