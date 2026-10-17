import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../components"
import "../services"
import "../theme"

// Full player: switcher, art, seekable progress and transport controls.
Item {
    id: root
    readonly property var player: Players.player
    readonly property color accent: art.status === Image.Ready && quantizer.colors.length ? quantizer.colors[0] : Theme.tertiary
    readonly property color cardColor: Qt.tint(Theme.surfaceContainerHigh, Qt.alpha(accent, 0.28))
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 32

    // ColorQuantizer only reads local files, and players often serve art over
    // https, so sample a snapshot of the loaded image instead. Alternate names
    // so each new snapshot is a new source.
    property int snapshot: 0
    function sampleArt() {
        art.grabToImage(result => {
            const path = Quickshell.cachePath("media-art-" + (snapshot % 2) + ".png");
            if (result.saveToFile(path)) quantizer.source = "file://" + path;
            snapshot++;
        }, Qt.size(64, 64));
    }
    ColorQuantizer {
        id: quantizer
        depth: 0
        rescaleSize: 64
    }

    Column {
        id: content
        x: 16; y: 16
        width: parent.width - 32
        spacing: 12

        Flow {
            width: parent.width
            spacing: 8
            visible: Players.players.length > 1
            Repeater {
                model: Players.players
                ActionChip {
                    required property var modelData
                    selected: modelData === root.player
                    icon: selected ? "check" : Players.icon(modelData)
                    text: modelData.identity
                    onClicked: Players.selected = modelData
                }
            }
        }

        Rectangle {
            width: parent.width
            height: card.implicitHeight + 32
            radius: 24
            color: root.cardColor
            Behavior on color { ColorAnimation { duration: Theme.durationMedium } }
            Column {
                id: card
                x: 16; y: 16
                width: parent.width - 32
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 16
                    ClippingRectangle {
                        width: 144; height: 144; radius: 16
                        color: Theme.tertiaryContainer
                        Icon { anchors.centerIn: parent; name: "album"; filled: true; size: 56; color: Theme.onTertiaryContainerColor }
                        Image {
                            id: art
                            anchors.fill: parent
                            source: root.player ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(288, 288)
                            asynchronous: true
                            visible: status === Image.Ready
                            onStatusChanged: if (status === Image.Ready) root.sampleArt()
                            Component.onCompleted: if (status === Image.Ready) root.sampleArt()
                        }
                    }
                    Column {
                        width: parent.width - 160
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Row {
                            spacing: 4
                            Icon { name: Players.icon(root.player); filled: true; size: 16; color: Theme.onSurfaceVariantColor }
                            StyledText { text: root.player ? root.player.identity : ""; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.onSurfaceVariantColor }
                        }
                        StyledText {
                            width: parent.width
                            text: root.player ? root.player.trackTitle || "Unknown track" : "Nothing playing"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            lineHeight: 1.1
                        }
                        StyledText {
                            width: parent.width
                            visible: text !== ""
                            text: root.player ? root.player.trackArtist : ""
                            color: Theme.onSurfaceVariantColor
                            font.weight: Font.Normal
                        }
                    }
                }

                WavyProgress {
                    width: parent.width
                    visible: root.player !== null && root.player.lengthSupported && root.player.length > 0
                    color: Theme.onSurfaceColor
                    value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                    playing: root.player !== null && root.player.isPlaying
                    seekable: root.player !== null && root.player.canSeek && root.player.positionSupported
                    onSeek: fraction => root.player.position = fraction * root.player.length
                }
                Item {
                    width: parent.width
                    height: 14
                    visible: root.player !== null && root.player.lengthSupported && root.player.length > 0
                    StyledText { text: Players.format(root.player ? root.player.position : 0); font.pixelSize: 12; color: Theme.onSurfaceVariantColor }
                    StyledText { anchors.right: parent.right; text: Players.format(root.player ? root.player.length : 0); font.pixelSize: 12; color: Theme.onSurfaceVariantColor }
                }

                Item {
                    width: parent.width
                    height: 56
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44; height: 44
                        icon: "shuffle"
                        tooltip: "Shuffle"
                        disabled: !root.player || !root.player.shuffleSupported
                        color: root.player && root.player.shuffle ? Theme.onSurfaceColor : "transparent"
                        contentColor: root.player && root.player.shuffle ? Theme.surfaceContainerHigh : Theme.onSurfaceColor
                        onClicked: root.player.shuffle = !root.player.shuffle
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: 12
                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48; height: 48
                            icon: "skip_previous"; filled: true; iconSize: 28
                            tooltip: "Previous"
                            disabled: !root.player || !root.player.canGoPrevious
                            onClicked: root.player.previous()
                        }
                        IconButton {
                            width: 72; height: 56
                            radius: root.player && root.player.isPlaying ? 16 : 28
                            Behavior on radius { NumberAnimation { duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                            color: Theme.primary
                            contentColor: Theme.onPrimaryColor
                            icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                            filled: true; iconSize: 30
                            tooltip: root.player && root.player.isPlaying ? "Pause" : "Play"
                            disabled: !root.player || !root.player.canTogglePlaying
                            onClicked: root.player.togglePlaying()
                        }
                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48; height: 48
                            icon: "skip_next"; filled: true; iconSize: 28
                            tooltip: "Next"
                            disabled: !root.player || !root.player.canGoNext
                            onClicked: root.player.next()
                        }
                    }
                    IconButton {
                        readonly property int loop: root.player ? root.player.loopState : MprisLoopState.None
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 44; height: 44
                        icon: loop === MprisLoopState.Track ? "repeat_one" : "repeat"
                        tooltip: loop === MprisLoopState.Track ? "Repeat one" : loop === MprisLoopState.Playlist ? "Repeat all" : "Repeat off"
                        disabled: !root.player || !root.player.loopSupported
                        color: loop !== MprisLoopState.None ? Theme.onSurfaceColor : "transparent"
                        contentColor: loop !== MprisLoopState.None ? Theme.surfaceContainerHigh : Theme.onSurfaceColor
                        onClicked: root.player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
                            : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                    }
                }
            }
        }
    }
}
