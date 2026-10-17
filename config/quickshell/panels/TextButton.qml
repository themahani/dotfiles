import QtQuick
import "../components"
import "../theme"

// Material text, tonal or filled button.
Rectangle {
    id: root
    property alias text: label.text
    property string icon: ""
    property string style: "text"       // "text", "tonal", "filled", "outlined" or "danger"
    signal clicked()
    readonly property color content: style === "filled" ? Theme.onPrimary : style === "tonal" ? Theme.onSecondaryContainer
        : style === "danger" ? Theme.onErrorContainer : style === "outlined" ? Theme.onSurfaceVariant : Theme.primary
    implicitWidth: row.implicitWidth + (style === "text" ? 24 : 32)
    implicitHeight: 36
    radius: height / 2
    color: style === "filled" ? Theme.primary : style === "tonal" ? Theme.secondaryContainer
        : style === "danger" ? Theme.errorContainer : "transparent"
    border.width: style === "outlined" ? 1 : 0
    border.color: Theme.outline
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        StyledText { id: label; font.pixelSize: 13; font.weight: Font.DemiBold; color: root.content }
        Icon { visible: root.icon !== ""; name: root.icon; size: 18; color: root.content; anchors.verticalCenter: parent.verticalCenter }
    }
    StateLayer { color: root.content; onClicked: root.clicked() }
}
