import QtQuick
import "../theme"

Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing
    implicitWidth: row.implicitWidth + 8
    implicitHeight: 38
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.blue
    border.width: 1
    Row { id: row; anchors.centerIn: parent; spacing: 4 }
}
