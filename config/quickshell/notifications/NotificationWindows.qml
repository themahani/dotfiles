import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"
import "../theme"

Scope {
    // Bar windows stay clickable while the center is open (see HyprlandFocusGrab).
    property var bars: []
    readonly property var output: Hyprland.focusedMonitor
        ? Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0]
        : Quickshell.screens[0]
    PanelWindow {
        id: center
        screen: output
        visible: Notifications.centerOpen
        // Backdrop below the bar: the layer rule blurs everything behind it,
        // and clicks outside the panel close it.
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: Theme.barHeight
        color: Qt.alpha(Theme.crust, 0.35)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        // Closes on clicks on other outputs and gives the panel keyboard focus.
        // Bars are included so their chips work, including the toggle.
        HyprlandFocusGrab {
            windows: [center, ...bars]
            active: center.visible
            onCleared: Notifications.centerOpen = false
        }
        MouseArea {
            anchors.fill: parent
            // Clicks on the panel's background fall through to here.
            onClicked: mouse => {
                if (!panel.contains(mapToItem(panel, mouse.x, mouse.y))) Notifications.centerOpen = false;
            }
        }
        ControlCenter {
            id: panel
            anchors { top: parent.top; right: parent.right; topMargin: 5; rightMargin: 5 }
            width: 350
            height: Math.min(700, parent.height - 10)
        }
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
