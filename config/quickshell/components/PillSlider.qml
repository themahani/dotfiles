import QtQuick
import "../theme"

// Pixel quick-settings slider: a thick track whose fill carries the icon.
Rectangle {
    id: root
    property real value: 0          // 0..1
    property string icon
    property string label: Math.round(value * 100) + "%"
    property string name: ""
    signal moved(real value)
    implicitHeight: 48
    radius: height / 2
    color: Theme.surfaceContainerHighest
    Accessible.role: Accessible.Slider
    Accessible.name: name
    function setFrom(x) { root.moved(Math.max(0, Math.min(1, (x - height / 2) / (width - height)))); }
    Rectangle {
        height: parent.height
        radius: parent.radius
        width: root.height + (root.width - root.height) * Math.max(0, Math.min(1, root.value))
        color: Theme.primary
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 100 } }
    }
    Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: root.icon; filled: true; color: Theme.onPrimary }
    StyledText {
        anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
        text: root.label
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: root.value > 0.82 ? Theme.onPrimary : Theme.onSurfaceVariant
    }
    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.setFrom(event.x)
        onPositionChanged: event => { if (pressed) root.setFrom(event.x); }
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
