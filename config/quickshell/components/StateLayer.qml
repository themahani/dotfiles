import QtQuick
import "../theme"

// Material state layer: tints its parent on hover and press, and handles input.
MouseArea {
    id: root
    property color color: Theme.onSurfaceColor
    property real radius: parent ? parent.radius || 0 : 0
    // Per-corner overrides, for layers covering only part of a rounded shape.
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
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
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: root.color
        opacity: root.pressed ? 0.12 : root.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
