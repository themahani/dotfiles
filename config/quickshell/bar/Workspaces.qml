import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

// Dots for this output's workspaces: active is a stretched pill, occupied a
// filled dot, empty an outlined one; urgent uses the error color.
Row {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(item => item.monitor === monitor && item.id > 0)
        .sort((a, b) => a.id - b.id)
    Repeater {
        model: root.workspaces
        Item {
            id: button
            required property var modelData
            readonly property bool active: root.monitor && root.monitor.activeWorkspace === modelData
            readonly property bool occupied: modelData.toplevels.values.length > 0
            width: dot.width + 10; height: 32
            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: button.active ? 24 : 8
                height: 8; radius: 4
                color: button.active ? Theme.primary : button.modelData.urgent ? Theme.error
                    : button.occupied ? Theme.onSurfaceVariantColor : "transparent"
                border.width: button.active || button.occupied || button.modelData.urgent ? 0 : 1.5
                border.color: Theme.outline
                Behavior on width { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on color { ColorAnimation { duration: Theme.durationShort } }
            }
            StateLayer {
                radius: 16
                onClicked: button.modelData.activate()
                onScrolled: direction => Hyprland.dispatch('hl.dsp.focus({ workspace = "m' + (direction > 0 ? "-1" : "+1") + '" })')
            }
            Accessible.role: Accessible.Button
            Accessible.name: "Workspace " + modelData.name
        }
    }
}
