import QtQuick
import "../components"
import "../services"
import "../theme"

// Bottom sheet with session actions. Restart and power off need a second
// click within three seconds.
Item {
    id: root
    property bool open: false
    property string confirming: ""
    signal close()
    visible: open || sheet.y < height
    onOpenChanged: confirming = ""

    readonly property var actions: [
        { id: "lock", icon: "lock", label: "Lock", command: ["loginctl", "lock-session"] },
        { id: "suspend", icon: "bedtime", label: "Suspend", command: ["systemctl", "suspend"] },
        { id: "logout", icon: "logout", label: "Log out", command: ["hyprshutdown"] },
        { id: "reboot", icon: "restart_alt", label: "Restart", confirm: "Click again to restart", command: ["systemctl", "reboot"] },
        { id: "poweroff", icon: "power_settings_new", label: "Power off", confirm: "Click again to power off", command: ["systemctl", "poweroff"] }
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.open ? 0.32 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationShort } }
        MouseArea { anchors.fill: parent; enabled: root.open; onClicked: root.close() }
    }
    Timer { id: reset; interval: 3000; onTriggered: root.confirming = "" }

    Rectangle {
        id: sheet
        x: 8
        width: parent.width - 16
        height: grid.implicitHeight + 34
        y: root.open ? parent.height - height - 8 : parent.height
        Behavior on y { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        topLeftRadius: 28; topRightRadius: 28; bottomLeftRadius: 20; bottomRightRadius: 20
        color: Theme.surfaceContainerLow
        MouseArea { anchors.fill: parent }
        Rectangle { y: 10; anchors.horizontalCenter: parent.horizontalCenter; width: 32; height: 4; radius: 2; color: Theme.outline; opacity: 0.5 }
        Flow {
            id: grid
            x: 12; y: 22
            width: parent.width - 24
            spacing: 8
            Repeater {
                model: root.actions
                Rectangle {
                    id: action
                    required property var modelData
                    required property int index
                    readonly property bool asking: root.confirming === modelData.id
                    readonly property bool wide: index === root.actions.length - 1
                    readonly property color content: asking ? Theme.onError : modelData.id === "poweroff" ? Theme.onPrimaryContainer : Theme.onSurface
                    width: wide ? grid.width : (grid.width - grid.spacing) / 2
                    height: 72
                    radius: 20
                    color: asking ? Theme.error : modelData.id === "poweroff" ? Theme.primaryContainer : Theme.surfaceContainerHighest
                    Behavior on color { ColorAnimation { duration: Theme.durationShort } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: action.modelData.icon; color: action.content }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: action.asking ? action.modelData.confirm : action.modelData.label
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: action.content
                        }
                    }
                    StateLayer {
                        color: action.content
                        onClicked: {
                            if (action.modelData.confirm && !action.asking) {
                                root.confirming = action.modelData.id;
                                reset.restart();
                                return;
                            }
                            reset.stop();
                            Panels.close();
                            Controls.run(action.modelData.command);
                        }
                    }
                }
            }
        }
    }
}
