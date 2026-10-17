import QtQuick
import "../theme"

// Material state layer: tints its parent on hover and press, and handles input.
MouseArea {
    id: root
    property color color: Theme.onSurfaceColor
    property real radius: parent ? parent.radius || 0 : 0
    property bool disabled: false
    signal scrolled(int direction)
    anchors.fill: parent
    hoverEnabled: true
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    // One scrolled() per wheel notch (120 units), however finely the wheel
    // reports; partial movement carries over to the next event.
    property real wheelRemainder: 0
    onWheel: event => {
        wheelRemainder += event.angleDelta.y;
        while (Math.abs(wheelRemainder) >= 120) {
            const direction = wheelRemainder > 0 ? 1 : -1;
            wheelRemainder -= direction * 120;
            root.scrolled(direction);
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.color
        opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
