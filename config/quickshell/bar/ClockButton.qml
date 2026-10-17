import QtQuick
import Quickshell
import "../components"
import "../services"
import "../theme"

BarButton {
    id: root
    required property var screen
    open: Panels.isOpen("clock", screen)
    tooltip: "Notifications and calendar"
    padding: 14
    onClicked: Panels.toggle("clock", screen)
    SystemClock { id: clock; precision: SystemClock.Minutes }
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "ddd MMM d")
        color: Theme.onSurfaceVariant
    }
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "h:mm AP")
        font.weight: Font.DemiBold
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: Notifications.count > 0 && !Notifications.dnd
        width: 6; height: 6; radius: 3
        color: Theme.primary
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Notifications.dnd
        name: "do_not_disturb_on"
        filled: true
        size: 16
        color: Theme.onSurfaceVariant
    }
}
