import QtQuick
import QtQuick.Controls as QtControls
import "../theme"

Rectangle {
    id: root
    property alias text: label.text
    property alias foreground: label.color
    property alias italic: label.font.italic
    property alias textFormat: label.textFormat
    property string tooltip: ""
    property int maximumWidth: 10000
    signal clicked(int button)
    signal scrolled(int direction)
    implicitWidth: Math.min(label.implicitWidth + 12, maximumWidth)
    implicitHeight: 30
    radius: 8
    color: mouse.containsMouse ? Theme.surface0 : "transparent"
    Label { id: label; anchors.fill: parent; anchors.margins: 6 }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => {
            if (event.angleDelta.y !== 0) root.scrolled(event.angleDelta.y > 0 ? 1 : -1);
        }
    }
    QtControls.ToolTip {
        parent: root
        // A separate popup can extend below the 42px panel instead of being
        // constrained to its overlay and covering the hovered module.
        popupType: QtControls.Popup.Window
        x: Math.round((root.width - width) / 2)
        y: root.height + 12
        margins: -1
        visible: mouse.containsMouse && root.tooltip.length > 0
        delay: 500
        text: root.tooltip
        padding: 10
        background: Rectangle {
            color: Theme.mantle
            radius: 8
            border.color: Theme.overlay0
            border.width: 1
        }
        contentItem: Label {
            text: root.tooltip
            color: Theme.text
            elide: Text.ElideNone
            font.bold: false
        }
    }
}
