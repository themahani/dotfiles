import QtQuick
import "../components"
import "../theme"

// Pill-shaped bar button; shows a filled state while its panel is open.
Rectangle {
    id: root
    default property alias content: row.data
    property bool open: false
    property string tooltip: ""
    property alias spacing: row.spacing
    property alias hovered: layer.containsMouse
    property int padding: 10
    signal clicked(int button)
    signal scrolled(int direction)
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 32
    radius: 16
    color: open ? Theme.surfaceContainerHighest : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.durationShort } }
    Row { id: row; anchors.centerIn: parent; spacing: 8 }
    StateLayer {
        id: layer
        onClicked: event => root.clicked(event.button)
        onScrolled: direction => root.scrolled(direction)
    }
    Tooltip { target: root; text: root.tooltip; shown: layer.containsMouse && !root.open }
}
