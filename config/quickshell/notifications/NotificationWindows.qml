import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"
import "../theme"

Scope {
    readonly property var output: Hyprland.focusedMonitor
        ? Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
        : Quickshell.screens[0]
    PanelWindow {
        id: center
        screen: output
        visible: Notifications.centerOpen
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + 5; right: 5 }
        implicitWidth: 350
        implicitHeight: Math.min(700, screen ? screen.height - Theme.barHeight - 10 : 700)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        ControlCenter { anchors.fill: parent }
    }
    PanelWindow {
        screen: output
        visible: Notifications.popups.length > 0 && !Notifications.centerOpen
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + 5; right: 5 }
        implicitWidth: 500
        implicitHeight: Math.min(cards.implicitHeight, screen ? screen.height - Theme.barHeight - 10 : 700)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        Flickable {
            anchors.fill: parent; clip: true
            contentHeight: cards.implicitHeight
            Column {
                id: cards; width: parent.width; spacing: 8
                Repeater {
                    model: Notifications.popups.slice().reverse()
                    NotificationCard { required property var modelData; width: cards.width; notification: modelData }
                }
            }
        }
    }
}
