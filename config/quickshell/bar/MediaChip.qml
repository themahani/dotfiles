import QtQuick
import Quickshell.Widgets
import "../components"
import "../services"
import "../theme"

Row {
    id: root
    required property var screen
    property real maximumWidth: 260
    readonly property var player: Players.player
    visible: player !== null
    spacing: 2
    BarButton {
        id: chip
        open: Panels.isOpen("media", root.screen)
        padding: 0
        width: Math.min(implicitWidth, root.maximumWidth - 34)
        implicitWidth: art.width + title.implicitWidth + 22
        onClicked: Panels.toggle("media", root.screen)
        Item { width: 4; height: 1 }
        ClippingRectangle {
            id: art
            anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 24; radius: 6
            color: Theme.tertiaryContainer
            Icon { anchors.centerIn: parent; name: Players.icon(root.player); filled: true; size: 16; color: Theme.onTertiaryContainerColor }
            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(48, 48)
                visible: status === Image.Ready
            }
        }
        StyledText {
            id: title
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maximumWidth - 34 - 22 - art.width)
            text: Players.track
            font.pixelSize: 13
            font.italic: root.player !== null && !root.player.isPlaying
            opacity: root.player && root.player.isPlaying ? 1 : 0.75
        }
    }
    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        width: 32; height: 32
        icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
        filled: true
        tooltip: root.player && root.player.isPlaying ? "Pause" : "Play"
        disabled: !root.player || !root.player.canTogglePlaying
        onClicked: root.player.togglePlaying()
    }
}
