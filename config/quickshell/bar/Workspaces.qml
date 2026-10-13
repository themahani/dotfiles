import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

Row {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    spacing: -8
    Repeater {
        model: Hyprland.workspaces
        Chip {
            required property var modelData
            visible: modelData.monitor === root.monitor
            text: modelData.name + " " + (modelData.active ? "" : modelData.toplevels.values.length ? "" : "")
            foreground: modelData.urgent ? Theme.red : modelData.active ? Theme.mauve : Theme.overlay1
            onClicked: modelData.activate()
        }
    }
}
