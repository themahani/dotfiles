import QtQuick
import "../theme"

// Material state layer: tints its parent on hover and press, and handles input.
MouseArea {
    id: root
    property color color: Theme.onSurface
    property real radius: parent ? parent.radius || 0 : 0
    property bool disabled: false
    signal scrolled(int direction)
    anchors.fill: parent
    hoverEnabled: true
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onWheel: event => {
        if (event.angleDelta.y !== 0) root.scrolled(event.angleDelta.y > 0 ? 1 : -1);
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.color
        opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
