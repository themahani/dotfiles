import QtQuick
import QtQuick.Controls as QtControls
import Quickshell
import Quickshell.Io
import "../components"
import "../services"
import "../theme"

Rectangle {
    id: root
    color: Theme.mantle
    radius: Theme.radius
    border.color: Theme.blue; border.width: 1
    focus: true
    Keys.onEscapePressed: Notifications.centerOpen = false
    Keys.onDeletePressed: Notifications.clear()
    Column {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8
        Chip {
            text: "Do Not Disturb: " + (Notifications.dnd ? "On" : "Off")
            foreground: Notifications.dnd ? Theme.red : Theme.text
            onClicked: Notifications.dnd = !Notifications.dnd
        }
        Flow {
            width: parent.width; spacing: 4
            Repeater {
                model: [
                    {icon: "󰐥", title: "Power off", command: ["systemctl", "poweroff"]},
                    {icon: "󰜉", title: "Reboot", command: ["systemctl", "reboot"]},
                    {icon: "󰌾", title: "Lock", script: "LockScreen.sh"},
                    {icon: "󰍃", title: "Log out", command: ["hyprctl", "dispatch", "exit"]},
                    {icon: "󰀝", title: "Airplane mode", script: "AirplaneMode.sh"},
                    {icon: "󰕾", title: "Mute output", audio: false},
                    {icon: "󰍬", title: "Mute microphone", audio: true}
                ]
                Chip {
                    required property var modelData
                    text: modelData.icon; tooltip: modelData.title
                    onClicked: {
                        if (modelData.command) Controls.run(modelData.command);
                        else if (modelData.script) Controls.hyprScript(modelData.script, "");
                        else Controls.volume("toggle", modelData.audio);
                    }
                }
            }
        }
        Label { text: "󰕾 Volume" }
        ThemedSlider {
            width: parent.width; from: 0; to: 150
            value: Controls.sink && Controls.sink.audio ? Controls.sink.audio.volume * 100 : 0
            onMoved: Controls.setVolume(value)
        }
        Label { text: "󰃟 Backlight"; visible: Metrics.data.brightness >= 0 }
        ThemedSlider {
            width: parent.width; from: 5; to: 100
            visible: Metrics.data.brightness >= 0
            value: Metrics.data.brightness
            onMoved: Controls.setBrightness(value)
        }
        Row {
            spacing: 8
            Label { text: "Notifications (" + Notifications.count + ")"; height: 30 }
            Chip { text: "Clear"; onClicked: Notifications.clear() }
            Chip { text: "×"; onClicked: Notifications.centerOpen = false }
        }
    }
    ListView {
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 12 }
        clip: true; spacing: 8
        model: Notifications.history.slice().reverse()
        delegate: NotificationCard {
            required property var modelData
            width: ListView.view.width
            notification: modelData
        }
        QtControls.ScrollBar.vertical: QtControls.ScrollBar {
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Theme.overlay0
                opacity: parent.active ? 1 : 0.5
            }
        }
    }
}
