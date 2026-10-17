import QtQuick
import "../components"
import "../theme"

// Clickable list row: leading icon, title and subtitle, trailing content.
Rectangle {
    id: root
    property string icon
    property bool iconFilled: true
    property string title
    property string subtitle
    property bool selected: false
    property bool circle: false
    property color iconBackground: Theme.surfaceContainerHighest
    property color iconColor: Theme.onSurfaceColor
    default property alias trailing: trailingRow.data
    signal clicked(int button)
    readonly property color content: selected ? Theme.onPrimaryContainerColor : Theme.onSurfaceColor
    implicitHeight: 60
    radius: 16
    color: selected ? Theme.primaryContainer : "transparent"
    StateLayer { color: root.content; onClicked: event => root.clicked(event.button) }
    Rectangle {
        id: lead
        x: root.circle ? 8 : 12
        anchors.verticalCenter: parent.verticalCenter
        width: root.circle ? 40 : 24; height: width; radius: width / 2
        color: root.circle ? root.iconBackground : "transparent"
        Icon { anchors.centerIn: parent; name: root.icon; filled: root.iconFilled; color: root.circle ? root.iconColor : root.content }
    }
    Column {
        anchors { left: lead.right; leftMargin: 14; right: trailingRow.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 2
        StyledText { width: parent.width; text: root.title; font.weight: Font.DemiBold; color: root.content }
        StyledText {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            font.pixelSize: 12
            font.weight: Font.Normal
            color: root.selected ? root.content : Theme.onSurfaceVariantColor
        }
    }
    Row {
        id: trailingRow
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 8
    }
}
