import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"
import "Markup.js" as Markup

// Summary, body, image and actions of one notification.
Column {
    id: root
    required property var notification
    property int bodyLines: 4
    spacing: 4
    StyledText {
        width: parent.width
        text: root.notification.summary
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }
    StyledText {
        width: parent.width
        visible: text.length > 0
        text: Markup.readableBody(root.notification.body)
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: root.bodyLines
        font.pixelSize: 13
        font.weight: Font.Normal
        color: Theme.onSurfaceVariant
        linkColor: Theme.primary
        lineHeight: 1.1
        onLinkActivated: link => Qt.openUrlExternally(link)
    }
    Image {
        visible: root.notification.image !== ""
        source: root.notification.image
        width: Math.min(220, parent.width)
        height: visible ? 110 : 0
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignLeft
    }
    Flow {
        width: parent.width
        spacing: 6
        topPadding: visible ? 4 : 0
        visible: actions.count > 0 || copyChip.visible
        Repeater {
            id: actions
            model: root.notification.actions.filter(action => action.identifier !== "default")
            ActionChip {
                required property var modelData
                text: modelData.text
                onClicked: modelData.invoke()
            }
        }
        ActionChip {
            id: copyChip
            readonly property var code: (root.notification.summary + " " + root.notification.body).match(/\b\d{4,8}\b/)
            visible: code !== null
            icon: "content_copy"
            text: code ? code[0] : ""
            onClicked: clipboard.running = true
            // Use an argument vector, never interpolate application text into a shell.
            Process { id: clipboard; command: ["wl-copy", "--", copyChip.code ? copyChip.code[0] : ""] }
        }
    }
}
