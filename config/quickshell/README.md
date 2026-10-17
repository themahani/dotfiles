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

- `theme/`: Material 3 color roles, type, shape and motion. Colors come from
  matugen (`config/matugen`), which `rofi-hyprpaper.sh` runs on every wallpaper
  change; `Theme` watches `~/.local/state/matugen/quickshell.json` and recolors
  live. Hyprland also runs matugen at login for its border, kitty, rofi and
  hyprlock (templates in `config/matugen/templates`). Each app first reads a
  committed fallback rendered from the same templates with Mocha blue
  (`theme/fallback.json` here), so without matugen output they all still share
  one Material 3 scheme. Run `config/matugen/render-fallbacks.py` after editing
  a template; a test fails while the fallbacks are stale.
- `components/`: Material building blocks (icons, state layers, buttons,
  switch, Pixel-style slider, concave fillet, sparkline, tooltip).
- `services/`: PipeWire controls, notifications, metrics, players, power,
  network summaries, and `Panels`, which tracks the one open dropdown.
- `bar/`: `Drawer` is one full-output window per screen holding the bar and the
  panel surface that grows out of it; `Reserver` reserves the bar's 40px.
- `panels/`: the system panel and its pages, notifications and calendar, media
  player, tray menus and notification popups.
- `osd/`: non-interactive feedback on the focused output, independent of DND.
- `scripts/metrics.py`: `/proc` statistics, `/sys` brightness, CPU temperature,
  rfkill and network counters, keyboard layout, and IP addresses. Memory updates
  every 10 seconds, disk every 30 seconds, everything else every second.

The bar is a single full-width surface whose bottom corners curve into the
screen edges at radius 10, concentric with Hyprland's window corners (rounding 8
plus gaps 2). Dropdowns grow out of it as the same surface, joined by the same
curves, and slide between anchors when you switch from one to another. Text uses
Roboto and icons use Material Symbols Rounded (`ttf-material-symbols-variable`).
Tray and window icons come from the GTK icon theme (as set with nwg-look):
`shell.qml` selects Qt's gtk3 platform theme, which needs a full Quickshell
restart to change. Tray apps that send their own pixmaps keep their icons.
Laptop-only items hide when the hardware is absent. Backend daemons
(`NetworkManager`, `bluetooth`, `upower`, `power-profiles-daemon`,
PipeWire/WirePlumber) must be running; installing packages does not enable them.

## Controls

- Left: tray icons (left or right click opens the app's menu in the bar, middle
  click is the secondary action, wheel scrolls) and the active window.
- Middle: workspace dots (click switches, wheel cycles), the clock (opens
  notifications and calendar), and the media chip (opens the player; its button
  plays or pauses directly). The chip hides when nothing is playing.
- Right: CPU and RAM (click opens btop), keyboard layout (click switches), and the
  status icons, which open the system panel; the wheel there changes volume.
- System panel: power menu (restart and power off need a second click), sliders,
  tiles for Wi-Fi, Bluetooth, stay awake, airplane mode, power profile and screen
  off, and system monitor cards that open btop. Chevrons open Wi-Fi, Bluetooth
  and sound device pages. Right-click a saved network to forget it.
- Notifications: groups expand, swipe or close to dismiss, Do not disturb and
  Clear all in the header; Backspace or Delete also clears all. Popups pause
  while hovered and swipe away.
- Escape, clicking outside, clicking the same bar item or another output closes
  the open panel.
- Super+N: notifications; Super+A: system panel; Super+Shift+D: DND.
- IPC: `panels toggle <system|clock|media>`, `panels openPage system
  <wifi|bluetooth|output|input|power>`, `panels tray <id>`, `panels close`.

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
quickshell -c desktop ipc call panels openPage system wifi
```

Do not launch the path-based test alongside another notification daemon. Test
tray menus, multi-output workspace switching, laptop discharge/charging, Bluetooth
pairing and battery reporting, Wi-Fi password entry, and hardware media keys in
your actual session. Restart Quickshell after adding or renaming files in a
directory with a `qmldir`; reloads do not re-read it.
The opt-in automated smoke test uses a private D-Bus session, so it can run
alongside the existing notification daemon without replacing it.

API reference: [Quickshell 0.3.2 types](https://quickshell.org/docs/v0.3.2/types/).
Package baseline: [Arch stable Quickshell](https://archlinux.org/packages/extra/x86_64/quickshell/).
