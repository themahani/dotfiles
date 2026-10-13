import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

Chip {
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var toplevel: Hyprland.toplevels.values.find(window =>
        window.monitor === monitor && window.activated) || Hyprland.toplevels.values.find(window =>
        monitor && monitor.activeWorkspace && window.address === monitor.activeWorkspace.lastIpcObject.lastwindow) || null
    visible: toplevel !== null
    foreground: Theme.mauve
    text: {
        if (!toplevel) return "";
        let title = toplevel.title;
        title = title.replace(/(.*) — Mozilla Firefox$/, " $1");
        title = title.replace(/(.*) - (fish|zsh|\$term)$/, "> [$1]");
        if (!toplevel.activated) title = "(inactive) " + title;
        return title.length > 25 ? title.slice(0, 24) + "…" : title;
    }
    tooltip: toplevel ? toplevel.title : ""
}
