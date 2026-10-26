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
- `lock/`: the session lock (`WlSessionLock`). Each output gets the blurred
  wallpaper and the bar's locked variant (lock label, notification count
  without content, media, keyboard layout, status icons opening brightness,
  volume and power). The focused output adds the clock, account, password
  field, fingerprint prompt and player. Password and fingerprint are two PAM
  sessions running side by side, and whichever succeeds first unlocks:
  `lock/pam/password` is a password-only copy of system-auth (a test fails
  when their auth or account rules differ), and
  `lock/pam/fingerprint` listens with pam_fprintd while someone is at the lock
  screen (five mismatches end it until the next lock). The scan stops after 30
  seconds without input and starts again on a key press, pointer motion or a
  wake-up, so a suspend rarely finds it open. The fingerprint prompt
  only appears when `fprintd-list` shows enrolled fingers. Only a successful
  PAM check unlocks; IPC can lock but not unlock. The shell also locks on
  logind's Lock signal and before every suspend, holding a sleep delay
  inhibitor until the compositor confirms the lock, and sets logind's
  LockedHint. hypridle keeps the idle timers and app inhibitors.
- `osd/`: non-interactive feedback on the focused output, independent of DND.
- `session/`: the full-screen session menu, which replaced wlogout. It shows
  lock, reboot, shut down, log out, suspend and hibernate on the focused
  output; hibernate only when logind's CanHibernate says yes. Each action
  keeps its wlogout key (l, r, s, e, u, h). Arrows or Tab move the
  highlight, Enter runs it, and Escape or a click outside closes the menu.
- `scripts/metrics.py`: CPU and memory from `/proc`, CPU temperature and the
  Caps Lock LED from `/sys`, and brightness and airplane mode from kernel
  change notifications (`actual_brightness` and `/dev/rfkill`), which it
  reports as they happen. It reads files only and starts no processes. Memory updates every 10 seconds, disk every 30
  seconds, everything else every second. The keyboard layout comes from
  Hyprland's events (`services/Keyboard.qml`).

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
- Middle: workspace dots (click switches, wheel steps without wrapping), the
  clock (opens notifications and calendar), and the media chip (opens the
  player; its button plays or pauses directly). The chip hides when nothing is playing.
- Right: CPU and RAM (click opens btop), keyboard layout (click switches), and the
  status icons, which open the system panel; the wheel there changes volume.
- System panel: power menu (restart and power off need a second click), sliders,
  tiles for Wi-Fi, Bluetooth, stay awake, airplane mode, power profile and screen
  off, and system monitor cards that open btop. Chevrons open Wi-Fi, Bluetooth
  and sound device pages. Right-click a saved network to forget it.
- Bluetooth pairing: the shell runs bluez's agent (`bluetoothctl --agent
  KeyboardDisplay`) as the default agent, so pairing shows the passkey to
  compare, asks for a PIN, or shows a code to type on the device, inline on the
  Bluetooth page. Requests from other devices open that page; while locked they
  are refused. Without the agent the page doesn't offer pairing.
- Notifications: groups expand, swipe or close to dismiss, Do not disturb and
  Clear all in the header; Backspace or Delete also clears all. Popups pause
  while hovered and swipe away.
- Workspaces are dynamic, as in GNOME, with one strip per monitor
  (`config/hypr/dynamic-workspaces.lua`). Each strip ends with one empty
  workspace, the outlined dot, once the last workspace has windows. An empty
  workspace disappears when you leave it. Super+[ / ] and Super+Alt+H/L step
  through the strip, Super+1..9 jump by position, and adding Shift takes the
  focused window along.
- Escape, clicking outside, clicking the same bar item or another output closes
  the open panel.
- Super+N: notifications; Super+A: system panel; Super+Shift+D: DND;
  Super+Escape: lock (through `loginctl lock-session`; the shell locks on
  logind's Lock signal, and hypridle falls back to hyprlock when Quickshell is
  not running); Super+X: session menu.
- IPC: `panels toggle <system|clock|media>`, `panels openPage system
  <wifi|bluetooth|output|input|power>`, `panels tray <id>`, `panels close`,
  `session toggle`, `session close`.

Normal popups hide after 6 seconds, low urgency after 3, critical after 12.
A positive application timeout takes precedence; a timeout of 0 ("never
expire") gets the default for its urgency. During Do not disturb only critical notifications
pop up. Non-transient notifications remain in session
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
notify-send -u critical 'Critical test' 'Hides after 12 seconds'
notify-send -A open=Open 'Action test' 'Try the action'
quickshell -c desktop ipc call controls volume inc
quickshell -c desktop ipc call notifications toggleDnd
quickshell -c desktop ipc call panels openPage system wifi
```

If the lock screen ever fails while locked, Hyprland keeps the session locked.
Switch to a TTY and run `hyprctl --instance 0 dispatch exec "quickshell -c desktop --no-duplicate"`
(or `hyprlock`); `misc:allow_session_lock_restore` lets a new locker take over.

Do not launch the path-based test alongside another notification daemon. Test
tray menus, multi-output workspace switching, laptop discharge/charging, Bluetooth
pairing and battery reporting, Wi-Fi password entry, and hardware media keys in
your actual session. Restart Quickshell after adding or renaming files in a
directory with a `qmldir`; reloads do not re-read it.
The opt-in automated smoke test uses a private D-Bus session, so it can run
alongside the existing notification daemon without replacing it.

API reference: [Quickshell 0.3.2 types](https://quickshell.org/docs/v0.3.2/types/).
Package baseline: [Arch stable Quickshell](https://archlinux.org/packages/extra/x86_64/quickshell/).
