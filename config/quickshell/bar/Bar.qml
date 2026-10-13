import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"
import "../theme"

PanelWindow {
    id: root
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    IdleInhibitor { window: root; enabled: Controls.idleInhibited }

    Island {
        id: left
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        Tray { window: root }
        WindowTitle { screen: root.screen; maximumWidth: Math.max(80, Math.min(220, root.width - right.width - center.width - 40)) }
    }
    Island {
        id: center
        // Stay centered when possible; avoid collisions on smaller outputs.
        x: Math.max(left.width + 4, Math.min((root.width - width) / 2, root.width - right.width - width - 4))
        anchors.verticalCenter: parent.verticalCenter
        border.color: Theme.overlay0
        Workspaces { screen: root.screen }
        Media { maximumWidth: Math.max(80, Math.min(260, root.width - left.width - right.width - 280)) }
        Clock {}
    }
    Island {
        id: right
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        Status {}
    }
}
