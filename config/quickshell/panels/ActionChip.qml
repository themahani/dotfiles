import QtQuick
import "../components"
import "../theme"

Rectangle {
    id: root
    property alias text: label.text
    property string icon: ""
    property bool selected: false
    signal clicked()
    implicitWidth: row.implicitWidth + 24
    implicitHeight: 32
    radius: 8
    color: selected ? Theme.secondaryContainer : "transparent"
    border.width: selected ? 0 : 1
    border.color: Theme.outlineVariant
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            filled: true
            size: 18
            color: label.color
        }
        StyledText {
            id: label
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.selected ? Theme.onSecondaryContainer : Theme.onSurfaceVariant
        }
    }
    StateLayer { color: label.color; onClicked: root.clicked() }
}
