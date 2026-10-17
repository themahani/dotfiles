import QtQuick
import Quickshell
import "../bar"
import "../components"
import "../services"
import "../theme"

// Clock, calendar and notification history, grouped by app.
Item {
    id: root
    readonly property var groups: {
        const byApp = {}, order = [];
        Notifications.history.slice().reverse().forEach(item => {
            const app = item.appName || "Notifications";
            if (!byApp[app]) { byApp[app] = []; order.push(app); }
            byApp[app].push(item);
        });
        return order.map(app => ({ app: app, items: byApp[app] }));
    }
    property string expandedApp: ""
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 32

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        id: content
        x: 16; y: 16
        width: parent.width - 32
        spacing: 12

        Item {
            width: parent.width
            height: 72
            Column {
                anchors.bottom: parent.bottom
                StyledText {
                    text: Qt.formatDateTime(clock.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
                    font.pixelSize: 44
                    font.weight: Font.Normal
                    height: 50
                }
                StyledText {
                    text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    color: Theme.onSurfaceVariantColor
                    font.weight: Font.Normal
                }
            }
            BarButton {
                anchors { right: parent.right; bottom: parent.bottom; bottomMargin: 4 }
                implicitHeight: 36
                radius: 18
                color: Theme.surfaceContainerHighest
                padding: 12
                spacing: 2
                onClicked: calendar.expanded = !calendar.expanded
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: calendar.expanded ? "Week" : "Month"; font.pixelSize: 13; font.weight: Font.DemiBold }
                Icon { anchors.verticalCenter: parent.verticalCenter; name: calendar.expanded ? "expand_less" : "expand_more" }
            }
        }

        CalendarCard { id: calendar; width: parent.width }

        Item {
            width: parent.width
            height: 40
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4
                ActionChip {
                    icon: "do_not_disturb_on"
                    text: "Do not disturb"
                    selected: Notifications.dnd
                    onClicked: Notifications.dnd = !Notifications.dnd
                }
                BarButton {
                    visible: Notifications.count > 0
                    onClicked: Notifications.clear()
                    StyledText { text: "Clear all"; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.primary }
                }
            }
        }

        Flickable {
            id: history
            width: parent.width
            height: Math.min(Math.max(list.implicitHeight, 120), 440)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: list
                width: parent.width
                spacing: 8
                Repeater {
                    model: root.groups
                    NotificationGroup {
                        required property var modelData
                        width: list.width
                        app: modelData.app
                        items: modelData.items
                        expanded: root.expandedApp === modelData.app
                        onToggleExpanded: root.expandedApp = expanded ? "" : modelData.app
                    }
                }
            }
            Column {
                parent: history        // the content item has no height when empty
                anchors.centerIn: parent
                visible: Notifications.count === 0
                spacing: 8
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "notifications_off"; size: 32; color: Theme.onSurfaceVariantColor }
                StyledText { text: "No notifications"; color: Theme.onSurfaceVariantColor; font.weight: Font.Normal }
            }
        }
    }
}
