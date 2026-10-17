import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../services"
import "../theme"

// Volume and brightness feedback on the focused output; never takes input.
PanelWindow {
    visible: Controls.osdVisible
    screen: Quickshell.screens.find(output => Hyprland.focusedMonitor && output.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 320; implicitHeight: 56
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainer
        Icon {
            id: icon
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            name: Controls.osdIcon
            filled: true
            color: Theme.primary
        }
        Rectangle {
            id: track
            anchors { left: icon.right; leftMargin: 16; right: value.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
            height: 8; radius: 4
            color: Theme.surfaceContainerHighest
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, Controls.osdValue / 100))
                height: parent.height; radius: 4
                color: Theme.primary
                Behavior on width { NumberAnimation { duration: 100 } }
            }
        }
        StyledText {
            id: value
            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
            width: 40
            horizontalAlignment: Text.AlignRight
            text: Controls.osdValue + "%"
            font.weight: Font.DemiBold
        }
        Accessible.role: Accessible.ProgressBar
        Accessible.name: Controls.osdLabel
    }
}
