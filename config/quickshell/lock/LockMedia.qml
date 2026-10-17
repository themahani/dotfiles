import QtQuick
import Quickshell.Widgets
import "../components"
import "../panels"
import "../services"
import "../theme"

// Compact player under the password field.
Rectangle {
    id: root
    readonly property var player: Players.player
    implicitWidth: 420
    implicitHeight: column.implicitHeight + 22
    radius: 24
    color: Qt.alpha(Theme.surfaceContainer, 0.85)
    Column {
        id: column
        x: 12; y: 12
        width: parent.width - 24
        spacing: 6
        Row {
            width: parent.width
            spacing: 14
            ClippingRectangle {
                width: 64; height: 64; radius: 12
                color: Theme.tertiaryContainer
                Icon { anchors.centerIn: parent; name: "album"; filled: true; size: 30; color: Theme.onTertiaryContainerColor }
                Image {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(128, 128)
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }
            Column {
                width: parent.width - 64 - 14 - controls.width - 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                StyledText { width: parent.width; text: root.player ? root.player.trackTitle || root.player.identity : ""; font.pixelSize: 16; font.weight: Font.DemiBold }
                StyledText { width: parent.width; visible: text !== ""; text: root.player ? root.player.trackArtist : ""; font.pixelSize: 13; font.weight: Font.Normal; color: Theme.onSurfaceVariantColor }
            }
            Row {
                id: controls
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_previous"; filled: true; iconSize: 24; tooltip: "Previous"
                    disabled: !root.player || !root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
                IconButton {
                    width: 48; height: 48
                    radius: root.player && root.player.isPlaying ? 14 : 24
                    Behavior on radius { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    color: Theme.primary
                    contentColor: Theme.onPrimaryColor
                    icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                    filled: true; iconSize: 26
                    tooltip: root.player && root.player.isPlaying ? "Pause" : "Play"
                    disabled: !root.player || !root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
                }
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "skip_next"; filled: true; iconSize: 24; tooltip: "Next"
                    disabled: !root.player || !root.player.canGoNext
                    onClicked: root.player.next()
                }
            }
        }
        WavyProgress {
            width: parent.width
            height: 20
            visible: root.player !== null && root.player.lengthSupported && root.player.length > 0
            color: Theme.onSurfaceColor
            value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            playing: root.player !== null && root.player.isPlaying
            seekable: root.player !== null && root.player.canSeek && root.player.positionSupported
            onSeek: fraction => root.player.position = fraction * root.player.length
        }
    }
}
