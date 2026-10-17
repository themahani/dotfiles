import QtQuick
import "../components"
import "../theme"

// Pixel quick-settings tile. With a chevron, the body toggles and the
// chevron opens the detail page.
Rectangle {
    id: root
    property string icon
    property string label
    property string subtitle
    property bool active: false
    property bool hasDetails: false
    signal toggled()
    signal details()
    readonly property color content: active ? Theme.onPrimaryColor : Theme.onSurfaceColor
    implicitHeight: 64
    radius: 32
    color: active ? Theme.primary : Theme.surfaceContainerHighest
    Behavior on color { ColorAnimation { duration: Theme.durationShort } }
    clip: true
    Item {
        id: body
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: chevron.visible ? chevron.left : parent.right }
        Icon { id: glyph; x: 18; anchors.verticalCenter: parent.verticalCenter; name: root.icon; filled: root.active; color: root.content }
        Column {
            anchors { left: glyph.right; leftMargin: 12; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            StyledText { width: parent.width; text: root.label; font.weight: Font.DemiBold; color: root.content }
            StyledText { width: parent.width; text: root.subtitle; font.pixelSize: 12; font.weight: Font.Normal; color: root.content; opacity: 0.82 }
        }
        StateLayer {
            color: root.content
            radius: root.radius
            topRightRadius: chevron.visible ? 0 : root.radius
            bottomRightRadius: chevron.visible ? 0 : root.radius
            onClicked: root.toggled()
        }
        Accessible.role: Accessible.CheckBox
        Accessible.name: root.label
        Accessible.checked: root.active
    }
    Item {
        id: chevron
        visible: root.hasDetails
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 44
        Rectangle { width: 1; height: parent.height - 24; anchors.verticalCenter: parent.verticalCenter; color: root.content; opacity: 0.25 }
        Icon { anchors.centerIn: parent; name: "chevron_right"; color: root.content }
        StateLayer {
            color: root.content
            radius: root.radius
            topLeftRadius: 0
            bottomLeftRadius: 0
            onClicked: root.details()
        }
        Accessible.role: Accessible.Button
        Accessible.name: root.label + " settings"
    }
}
