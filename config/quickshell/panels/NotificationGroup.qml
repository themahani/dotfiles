import QtQuick
import "../components"
import "../services"
import "../theme"

// One app's notifications. Collapsed it shows the newest; swipe sideways to dismiss.
Rectangle {
    id: root
    required property string app
    required property var items
    property bool expanded: false
    signal toggleExpanded()
    readonly property var latest: items[0]
    function dismiss() { items.slice().forEach(item => item.dismiss()); }

    implicitHeight: column.implicitHeight + 26
    radius: 20
    color: Theme.surfaceContainerHigh
    border.width: latest.urgency === 2 ? 1 : 0
    border.color: Theme.error
    opacity: 1 - Math.min(Math.abs(x) / 260, 0.7)
    Behavior on x { enabled: !swipe.active; NumberAnimation { duration: Theme.durationShort; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

    DragHandler {
        id: swipe
        yAxis.enabled: false
        target: root
        onActiveChanged: if (!active) {
            if (Math.abs(root.x) > 110) root.dismiss();
            else root.x = 0;
        }
    }
    // A click opens the notification under the pointer, or the newest one
    // when it lands on the header.
    StateLayer {
        onClicked: event => {
            const row = column.childAt(event.x - column.x, event.y - column.y);
            if (Notifications.activate(row && row.notification ? row.notification : root.latest)) Panels.close();
        }
    }
    Column {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12; leftMargin: 12; rightMargin: 10; topMargin: 12 }
        spacing: 8
        Item {
            width: parent.width
            height: 32
            AppIcon { id: icon; source: root.latest.appIcon }
            StyledText {
                id: name
                anchors { left: icon.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                width: Math.min(implicitWidth, parent.width - icon.width - time.implicitWidth - buttons.width - 28)
                text: root.app
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            StyledText {
                id: time
                anchors { left: name.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: "· " + Notifications.since(root.latest)
                font.pixelSize: 12
                font.weight: Font.Normal
                color: Theme.onSurfaceVariantColor
            }
            Row {
                id: buttons
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 2
                Rectangle {
                    visible: root.items.length > 1
                    width: count.implicitWidth + 30; height: 28; radius: 14
                    color: Theme.surfaceContainerHighest
                    Row {
                        anchors.centerIn: parent
                        StyledText { id: count; text: root.items.length; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Icon { name: root.expanded ? "expand_less" : "expand_more"; size: 18 }
                    }
                    StateLayer { onClicked: root.toggleExpanded() }
                }
                IconButton { width: 28; height: 28; icon: "close"; iconSize: 18; tooltip: "Dismiss"; onClicked: root.dismiss() }
            }
        }
        Repeater {
            model: root.expanded ? root.items : root.items.slice(0, 1)
            NotificationItem {
                required property var modelData
                x: 42
                width: column.width - 46
                notification: modelData
                bodyLines: root.expanded ? 6 : 3
            }
        }
    }
}
