import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../services"
import "../theme"

PanelWindow {
    visible: Controls.osdVisible
    screen: Quickshell.screens.find(output => Hyprland.focusedMonitor && output.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 300; implicitHeight: 60
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}
    Rectangle {
        anchors.fill: parent
        color: Theme.base; radius: Theme.radius
        border.color: Theme.blue; border.width: 1
        Column {
            anchors { fill: parent; margins: 10 }
            spacing: 12
            Label { width: parent.width; text: Controls.osdIcon + " " + Controls.osdLabel + " " + Controls.osdValue + "%"; color: Theme.sapphire }
            Rectangle {
                width: parent.width; height: 8; radius: 4; color: Theme.surface1
                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0, Controls.osdValue / 100))
                    height: parent.height; radius: 4; color: Theme.sapphire
                    Behavior on width { NumberAnimation { duration: 100 } }
                }
            }
        }
    }
}
