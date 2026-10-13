# Desktop shell

Targets **Quickshell 0.3.2 stable**, Qt 6, and Hyprland on Wayland. Use Arch's
`quickshell` package, not `quickshell-git`; Qt dependencies should come from the
same fully updated repository, not mixed Qt versions. No third-party QML modules
or development-only APIs are used. `manifests/modules.json` declares dependencies.

## Enable

Run the usual `./install apply` for your desktop profile to link this directory
as `$XDG_CONFIG_HOME/quickshell/desktop`. Restart the desktop session, or stop
the existing Waybar and SwayNC processes yourself and run:

```sh
quickshell -c desktop --no-duplicate
```

Only one notification daemon can own `org.freedesktop.Notifications`. Disable
any user service/autostart for SwayNC, Dunst, or another notification daemon.
Existing `hypr.local.lua` autostart overrides must also be updated. The installer
does not uninstall old packages or terminate your running desktop processes.

## Structure

- `theme/`: original Mocha palette, typography, and dimensions.
- `components/`: shared labels, clickable chips, and bar islands.
- `services/`: shared PipeWire controls, notifications, IPC, and metrics.
- `bar/`: output-aware workspaces/window titles, tray, media, and system modules.
- `notifications/`: notification cards, history, DND, actions, images, code copy,
  quick actions, and audio/backlight sliders.
- `osd/`: non-interactive feedback on the focused output, independent of DND.
- `scripts/metrics.py`: `/proc` statistics, `/sys` brightness/network counters,
  keyboard layout, and IP addresses. Memory updates every 10 seconds, disk every
  30 seconds; CPU, keyboard, backlight, and network rates update every second.

The bar preserves the old left/center/right module order, 42px reservation,
Mocha module colors, blue outer borders, and overlay center border. Laptop-only
modules hide when hardware is absent. Idle inhibition retains the original
bright-green indicator. Native Quickshell services provide tray menus, MPRIS,
PipeWire, UPower, power profiles, NetworkManager, Bluetooth, and Hyprland state.
Text uses Ubuntu Nerd Font (`ttf-ubuntu-nerd`) with 0.5px letter spacing.
Tooltips use explicit Mocha text/background colors; application notification
markup cannot override text colors. Tray icons request output-scaled source
sizes and use mipmap filtering rather than stretching a default-sized bitmap.
Backend daemons (`NetworkManager`, `bluetooth`, `upower`, `power-profiles-daemon`,
PipeWire/WirePlumber) must be running; installing packages does not enable them.
Power-profile driver names are collected from `powerprofilesctl list` every
30 seconds and shown in the profile tooltip.

## Controls

- Super+N: notification center; Super+Shift+D: DND.
- Notification chip: left opens history, right toggles DND.
- Media: left previous, middle play/pause, right next; wheel adjusts output.
- CPU/memory/clock/battery: left toggles alternate display.
- CPU/memory: right opens btop; battery: right opens wlogout.
- Audio/microphone: left mute, wheel ±5%, right opens pavucontrol.
- Backlight: wheel ±10%, clamped to 5–100%; output volume allows 150% boost.
- Power profile: click cycles available profiles.
- Keyboard: click advances the actual main keyboard's layout.
- Network: right opens connection editor; Bluetooth: click opens blueberry.
- Tray: left/right opens available menus; middle invokes the secondary action.
  Items without menus use their activation action. Platform menus require the
  `UseQApplication` pragma in `shell.qml`; changes to this pragma require a full
  Quickshell restart, not just a QML reload.
- Tray menus are native Qt Widgets menus, including their submenus, checkboxes,
  and keyboard navigation. `RespectSystemStyle` allows native Qt styling, and
  `qt6ct` is the default platform theme when none is already selected. The desktop
  manifest links the Mocha blue-accent palette and Qt6 settings under `qt6ct`.
  These settings also affect other apps that use the qt6ct platform plugin.
  Existing platform-theme environment overrides are respected. Apply the config
  links and install `qt6ct`, then restart Quickshell to activate native theming.
  The installer preserves existing settings unless you explicitly request backup
  and replacement; merge the Appearance/Fonts settings manually if preferred.
  `config/qt6ct/qss/tray-menus.qss` matches tooltip borders (1px overlay0,
  8px corners, mantle background). qt6ct requires an absolute stylesheet path;
  update `Appearance.stylesheets` in `config/qt6ct/qt6ct.conf` when installing
  this checkout under a different home/path. Restart Quickshell after changing
  native menu styling.
- Center: Escape closes, Delete clears; quick actions match the old SwayNC grid.

Normal popups hide after 6 seconds, low urgency after 3, critical notifications
remain until dismissed; explicit application timeouts take precedence for
non-critical notifications. Non-transient notifications remain in session
history after the popup hides. Actions are invoked through the notification
protocol. Inline replies remain disabled, matching the previous configuration.
History survives QML reloads, but not a process/session restart. Verification
codes of 4–8 digits can be copied using wl-copy.

## Validate

```sh
python3 -B -m unittest discover -s tests -v
DOTFILES_TEST_QUICKSHELL=1 python3 -B -m unittest discover -s tests -p test_quickshell.py -v
quickshell -p ./config/quickshell
notify-send 'Shell test' 'Normal notification'
notify-send -u critical 'Critical test' 'Dismiss manually'
notify-send -A open=Open 'Action test' 'Try the action'
quickshell -c desktop ipc call controls volume inc
quickshell -c desktop ipc call notifications toggleDnd
```

Do not launch the path-based test alongside another notification daemon. Test
tray menus, multi-output workspace switching, laptop discharge/charging, Bluetooth
device battery reporting, and hardware media keys in your actual session.
The opt-in automated smoke test uses a private D-Bus session, so it can run
alongside the existing notification daemon without replacing it.

API reference: [Quickshell 0.3.2 types](https://quickshell.org/docs/v0.3.2/types/).
Package baseline: [Arch stable Quickshell](https://archlinux.org/packages/extra/x86_64/quickshell/).
