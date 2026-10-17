import QtQuick
import "../theme"

// Plain text unless a caller opts in: window titles, track titles, network
// and device names come from other people, and rich text would load their
// <img> URLs and apply their styling.
Text {
    textFormat: Text.PlainText
    color: Theme.onSurfaceColor
    font.family: Theme.font
    font.pixelSize: 14
    font.weight: Font.Medium
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
