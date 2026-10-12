-- Copy to ~/.config/dotfiles/hypr.extra.lua.
-- Executes after the base config and display layouts; use Hyprland's hl API here.
-- Keyboard, mouse, launcher commands, and startup lists belong in hypr.local.lua.
-- Hyprland's LuaLS API types are provided by /usr/share/hypr/stubs.
hl.bind("SUPER + B", hl.dsp.exec_cmd("your-browser-command"))
