import QtQuick
import Quickshell.Hyprland
import "../components"
import "../theme"

// Dots for this output's workspaces, GNOME style (config/hypr/dynamic-workspaces.lua):
// active is a stretched pill, occupied a filled dot, urgent the error color.
// Hyprland drops empty workspaces once they are left, so the only outlined dot
// is the trailing empty workspace after the last one with windows.
Row {
    id: root
    required property var screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(item => item.monitor === monitor && item.id > 0)
        .sort((a, b) => a.id - b.id)
    readonly property var last: workspaces[workspaces.length - 1]
    // null stands for the trailing empty workspace, which Hyprland creates on arrival.
    readonly property var slots: !last || last.toplevels.values.length > 0 ? workspaces.concat([null]) : workspaces
    function dynamic(name, argument) {
        if (monitor)
            Hyprland.dispatch("dynamic_workspaces." + name + "(" + argument + ', "' + monitor.name + '")')
    }
    Repeater {
        model: root.slots
        Item {
            id: button
            required property var modelData
            required property int index
            readonly property bool active: !!modelData && !!root.monitor && root.monitor.activeWorkspace === modelData
            readonly property bool occupied: !!modelData && modelData.toplevels.values.length > 0
            readonly property bool urgent: !!modelData && modelData.urgent
            width: dot.width + 10; height: 32
            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: button.active ? 24 : 8
                height: 8; radius: 4
                color: button.active ? Theme.primary : button.urgent ? Theme.error
                    : button.occupied ? Theme.onSurfaceVariantColor : "transparent"
                border.width: button.active || button.occupied || button.urgent ? 0 : 1.5
                border.color: Theme.outline
                Behavior on width { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on color { ColorAnimation { duration: Theme.durationShort } }
            }
            StateLayer {
                radius: 16
                onClicked: button.modelData ? button.modelData.activate() : root.dynamic("focus_index", button.index + 1)
                onScrolled: direction => root.dynamic("focus", direction > 0 ? -1 : 1)
            }
            Accessible.role: Accessible.Button
            Accessible.name: modelData ? "Workspace " + (index + 1) : "New workspace"
        }
    }
}
