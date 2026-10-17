import QtQuick
import Quickshell
import Quickshell.Widgets
import "../components"
import "../theme"

// A notification's app icon in a tonal circle, or a generic bell.
Rectangle {
    id: root
    property string source: ""
    property string fallback: "notifications"
    readonly property string resolved: !source ? "" : source.startsWith("/") || source.includes(":") ? source : Quickshell.iconPath(source, true)
    implicitWidth: 32
    implicitHeight: 32
    radius: width / 2
    color: Theme.secondaryContainer
    IconImage {
        anchors.centerIn: parent
        visible: root.resolved !== ""
        implicitSize: Math.round(root.width * 0.6)
        source: root.resolved
        mipmap: true
    }
    Icon {
        anchors.centerIn: parent
        visible: root.resolved === ""
        name: root.fallback
        filled: true
        size: Math.round(root.width * 0.56)
        color: Theme.onSecondaryContainer
    }
}
