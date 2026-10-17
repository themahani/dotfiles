import QtQuick
import "../theme"

// Material outlined text field.
Rectangle {
    id: root
    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""
    signal accepted()
    function focusInput() { input.forceActiveFocus(); }
    implicitHeight: 40
    radius: 20
    color: "transparent"
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.primary : Theme.outline
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.onSurfaceColor
        selectionColor: Theme.primary
        selectedTextColor: Theme.onPrimaryColor
        font.family: Theme.font
        font.pixelSize: 14
        clip: true
        onAccepted: root.accepted()
        Accessible.name: root.placeholder
    }
    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.onSurfaceVariantColor
        font: input.font
    }
}
