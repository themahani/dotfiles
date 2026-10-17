import QtQuick
import "../components"
import "../services"
import "../theme"

// The lock screen's only settings: brightness, volume and power. Reboot and
// shut down need a second click within three seconds.
Item {
    id: root
    property string confirming: ""
    readonly property var audio: Controls.sink ? Controls.sink.audio : null
    readonly property var actions: Session.pick(["suspend", "reboot", "shutdown"])
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 32
    Timer { id: reset; interval: 3000; onTriggered: root.confirming = "" }

    Column {
        id: content
        x: 16; y: 16
        width: parent.width - 32
        spacing: 16
        Column {
            width: parent.width
            spacing: 8
            PillSlider {
                visible: Metrics.brightness >= 0
                width: parent.width
                name: "Brightness"
                icon: "brightness_6"
                value: Controls.brightnessValue / 100
                onMoved: value => Controls.setBrightness(Math.max(5, value * 100))
            }
            PillSlider {
                readonly property bool muted: !root.audio || root.audio.muted
                width: parent.width
                name: "Volume"
                value: muted ? 0 : Math.min(1, root.audio.volume)
                label: muted ? "Muted" : Math.round(root.audio.volume * 100) + "%"
                icon: muted || root.audio.volume === 0 ? "volume_off" : root.audio.volume < 0.4 ? "volume_down" : "volume_up"
                onMoved: value => {
                    if (!root.audio) return;
                    root.audio.muted = false;
                    root.audio.volume = value;
                }
            }
        }
        Row {
            width: parent.width
            spacing: 8
            Repeater {
                model: root.actions
                Rectangle {
                    id: action
                    required property var modelData
                    readonly property bool asking: root.confirming === modelData.id
                    readonly property color content: asking ? Theme.onErrorColor
                        : modelData.id === "shutdown" ? Theme.onPrimaryContainerColor : Theme.onSurfaceColor
                    width: (parent.width - 16) / 3
                    height: 72
                    radius: 20
                    color: asking ? Theme.error : modelData.id === "shutdown" ? Theme.primaryContainer : Theme.surfaceContainerHighest
                    Behavior on color { ColorAnimation { duration: Theme.durationShort } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: action.modelData.icon; color: action.content }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: action.asking ? "Click again" : action.modelData.label
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: action.content
                        }
                    }
                    StateLayer {
                        color: action.content
                        onClicked: {
                            if (action.modelData.confirm && !action.asking) {
                                root.confirming = action.modelData.id;
                                reset.restart();
                                return;
                            }
                            reset.stop();
                            Session.run(action.modelData.id);
                        }
                    }
                }
            }
        }
    }
}
