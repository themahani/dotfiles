import QtQuick
import "../components"
import "../services"
import "../theme"

// Heads-up notifications, newest on top, attached under the clock.
Item {
    id: root
    implicitWidth: 400
    implicitHeight: column.implicitHeight + 16
    Column {
        id: column
        x: 8; y: 8
        width: parent.width - 16
        spacing: 8
        Repeater {
            model: Notifications.popups.slice().reverse().slice(0, 3)
            Rectangle {
                id: card
                required property var modelData
                width: column.width
                height: body.implicitHeight + 24
                radius: 16
                color: Theme.surfaceContainerHigh
                border.width: modelData.urgency === 2 ? 1 : 0
                border.color: Theme.error
                opacity: 1 - Math.min(Math.abs(x) / 260, 0.7)
                Behavior on x { enabled: !swipe.active; NumberAnimation { duration: Theme.durationShort } }
                DragHandler {
                    id: swipe
                    yAxis.enabled: false
                    onActiveChanged: if (!active) {
                        if (Math.abs(card.x) > 110) Notifications.hidePopup(card.modelData.id);
                        else card.x = 0;
                    }
                }
                StateLayer {
                    radius: card.radius
                    onClicked: {
                        const action = card.modelData.actions.find(item => item.identifier === "default");
                        Notifications.hidePopup(card.modelData.id);
                        if (action) action.invoke();
                        else Panels.toggle("clock", null);
                    }
                }
                AppIcon { id: icon; x: 12; y: 12; width: 40; height: 40; source: card.modelData.appIcon }
                Column {
                    id: body
                    anchors { left: icon.right; leftMargin: 12; right: close.left; rightMargin: 4; top: parent.top; topMargin: 12 }
                    spacing: 2
                    StyledText {
                        width: parent.width
                        text: (card.modelData.appName || "Notification") + " · now"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.onSurfaceVariant
                    }
                    NotificationItem { width: parent.width; notification: card.modelData; bodyLines: 2 }
                }
                IconButton {
                    id: close
                    anchors { right: parent.right; rightMargin: 8; top: parent.top; topMargin: 8 }
                    width: 32; height: 32; icon: "close"; iconSize: 18; tooltip: "Dismiss"
                    onClicked: Notifications.hidePopup(card.modelData.id)
                }
            }
        }
    }
}
