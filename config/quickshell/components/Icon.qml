import QtQuick
import "../theme"

// Material Symbols Rounded glyph by ligature name, e.g. "wifi".
Text {
    property string name
    property bool filled: false
    property real size: 20
    text: name
    color: Theme.onSurfaceColor
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "opsz": Math.max(20, Math.min(48, size)), "wght": 400 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
