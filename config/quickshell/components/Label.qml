import QtQuick
import "../theme"

Text {
    color: Theme.text
    linkColor: Theme.blue
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
    font.letterSpacing: Theme.letterSpacing
    textFormat: Text.PlainText
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
