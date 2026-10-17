import QtQuick
import "../theme"

// Material 3 switch.
Rectangle {
    id: root
    property bool checked: false
    property string label: ""
    signal toggled()
    implicitWidth: 52
    implicitHeight: 32
    radius: 16
    color: checked ? Theme.primary : Theme.surfaceContainerHighest
    border.width: checked ? 0 : 2
    border.color: Theme.outline
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Rectangle {
        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        x: root.checked ? root.width - width - 4 : 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.onPrimary : Theme.outline
        Behavior on x { NumberAnimation { duration: Theme.durationShort; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on width { NumberAnimation { duration: Theme.durationShort } }
    }
    StateLayer { color: root.checked ? Theme.primary : Theme.onSurface; onClicked: root.toggled() }
}
