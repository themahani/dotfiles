import QtQuick
import "../components"
import "../panels"
import "../services"
import "../theme"

// Lock screen stand-in for the clock button: how many notifications are
// waiting and from which apps, without any of their content.
Item {
    id: root
    readonly property var apps: {
        const seen = [];
        Notifications.history.slice().reverse().forEach(item => {
            if (!seen.some(other => other.appName === item.appName)) seen.push(item);
        });
        return seen.slice(0, 3);
    }
    implicitWidth: row.implicitWidth + 28
    implicitHeight: 32
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Row {
            visible: root.apps.length > 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: -4
            Repeater {
                model: root.apps
                Rectangle {
                    required property var modelData
                    width: 26; height: 26; radius: 13
                    color: Theme.surfaceContainer
                    AppIcon { anchors.centerIn: parent; width: 22; height: 22; source: modelData.appIcon }
                }
            }
        }
        Icon { visible: Notifications.dnd; anchors.verticalCenter: parent.verticalCenter; name: "do_not_disturb_on"; filled: true; size: 16; color: Theme.onSurfaceVariantColor }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Notifications.count === 0 ? "No notifications"
                : Notifications.count + (Notifications.count === 1 ? " notification" : " notifications")
        }
    }
    HoverHandler { id: hover }
    Tooltip { target: root; text: "Unlock to read notifications"; shown: hover.hovered && Notifications.count > 0 }
}
