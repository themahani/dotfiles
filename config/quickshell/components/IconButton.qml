import QtQuick
import "../theme"

Rectangle {
    id: root
    property string icon
    property bool filled: false
    property real iconSize: 20
    property color contentColor: Theme.onSurfaceColor
    property string tooltip: ""
    property alias hovered: layer.containsMouse
    property alias disabled: layer.disabled
    signal clicked(int button)
    signal scrolled(int direction)
    implicitWidth: 40
    implicitHeight: 40
    radius: height / 2
    color: "transparent"
    opacity: layer.disabled ? 0.38 : 1
    Icon { anchors.centerIn: parent; name: root.icon; filled: root.filled; size: root.iconSize; color: root.contentColor }
    StateLayer {
        id: layer
        color: root.contentColor
        onClicked: event => root.clicked(event.button)
        onScrolled: direction => root.scrolled(direction)
    }
    Tooltip { target: root; text: root.tooltip; shown: layer.containsMouse }
}
