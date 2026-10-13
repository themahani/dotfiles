import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../services"
import "../theme"
import "Markup.js" as Markup

Rectangle {
    id: root
    required property var notification
    implicitHeight: content.implicitHeight + 20
    radius: Theme.radius
    color: Theme.base
    border.color: notification.urgency === 2 ? Theme.red : Theme.overlay0
    border.width: 1
    Column {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 8
        Row {
            width: parent.width; spacing: 8
            Image {
                width: 30; height: 30
                visible: root.notification.appIcon !== ""
                source: !root.notification.appIcon ? "" : root.notification.appIcon.startsWith("/") || root.notification.appIcon.includes(":")
                    ? root.notification.appIcon : Quickshell.iconPath(root.notification.appIcon)
                fillMode: Image.PreserveAspectFit
            }
            Column {
                width: parent.width - 80
                Label { width: parent.width; text: root.notification.appName; color: Theme.subtext0 }
                Label { width: parent.width; text: root.notification.summary; wrapMode: Text.Wrap; elide: Text.ElideNone }
            }
            Chip { text: "×"; tooltip: "Dismiss"; onClicked: root.notification.dismiss() }
        }
        Label {
            width: parent.width
            visible: text.length > 0
            text: Markup.readableBody(root.notification.body)
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            font.bold: false
            onLinkActivated: link => Qt.openUrlExternally(link)
        }
        Image {
            visible: root.notification.image !== ""
            source: root.notification.image
            width: Math.min(200, parent.width); height: visible ? 100 : 0
            fillMode: Image.PreserveAspectFit
        }
        Flow {
            width: parent.width; spacing: 4
            Repeater {
                model: root.notification.actions
                Chip {
                    required property var modelData
                    maximumWidth: content.width
                    text: modelData.text
                    foreground: Theme.blue
                    onClicked: modelData.invoke()
                }
            }
            Chip {
                id: copyChip
                readonly property var code: (root.notification.summary + " " + root.notification.body).match(/\b\d{4,8}\b/)
                visible: code !== null
                text: code ? "Copy " + code[0] : ""
                tooltip: "Copy verification code"
                onClicked: clipboard.running = true
                // Use an argument vector, never interpolate application text into a shell.
                property var copier: Process {
                    id: clipboard
                    command: ["wl-copy", "--", copyChip.code ? copyChip.code[0] : ""]
                }
            }
        }
    }
}
