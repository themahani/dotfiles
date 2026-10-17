import QtQuick
import QtQuick.Controls as QtControls
import "../theme"

// Plain Material tooltip in its own popup window, so it can leave the bar.
QtControls.ToolTip {
    id: root
    required property Item target
    property bool shown: false
    parent: target
    popupType: QtControls.Popup.Window
    x: Math.round((target.width - width) / 2)
    y: target.height + 8
    margins: -1
    visible: shown && text.length > 0
    delay: 600
    padding: 8
    background: Rectangle { color: Theme.inverseSurface; radius: 4 }
    contentItem: StyledText {
        text: root.text
        color: Theme.inverseOnSurface
        font.pixelSize: 12
        font.weight: Font.Normal
        elide: Text.ElideNone
    }
}
