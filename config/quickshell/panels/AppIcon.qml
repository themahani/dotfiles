import QtQuick
import Quickshell
import Quickshell.Widgets
import "../components"
import "../theme"
import "Markup.js" as Markup

// A notification's app icon in a tonal circle, or a generic bell.
Rectangle {
    id: root
    property string source: ""
    property string fallback: "notifications"
    // An icon name, or a local image; remote URLs fall back to the bell.
    readonly property string resolved: !source ? "" : Markup.isLocalImage(source) ? source
        : source.includes(":") ? "" : Quickshell.iconPath(source, true)
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
        color: Theme.onSecondaryContainerColor
    }
}
