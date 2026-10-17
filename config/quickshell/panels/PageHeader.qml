import QtQuick
import "../components"
import "../theme"

Item {
    id: root
    property string title
    default property alias trailing: trailingRow.data
    signal back()
    implicitHeight: 48
    IconButton { id: backButton; anchors.verticalCenter: parent.verticalCenter; icon: "arrow_back"; tooltip: "Back"; onClicked: root.back() }
    StyledText {
        anchors { left: backButton.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.title
        font.pixelSize: 18
        font.weight: Font.Medium
    }
    Row { id: trailingRow; anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
}
