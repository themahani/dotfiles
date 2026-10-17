import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../components"
import "../services"
import "../theme"

// Output (sink) or input (source) device picker.
Item {
    id: root
    property bool sinks: true
    signal back()
    readonly property var nodes: Pipewire.nodes.values.filter(node => node.audio && !node.isStream && node.isSink === sinks)
    readonly property var current: sinks ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource
    function icon(node) {
        const text = (node.description + " " + (node.properties["device.form-factor"] || "") + " " + node.name).toLowerCase();
        if (/headphone|headset|hands-free/.test(text)) return sinks ? "headphones" : "headset_mic";
        if (/hdmi|displayport|monitor/.test(text)) return "desktop_windows";
        if (/bluez|bluetooth/.test(text)) return "bluetooth";
        if (/usb/.test(text)) return "usb";
        return sinks ? "speaker" : "mic";
    }

    PageHeader { id: header; width: parent.width; title: root.sinks ? "Sound output" : "Sound input"; onBack: root.back() }

    Flickable {
        anchors { top: header.bottom; topMargin: 8; bottom: footer.top; bottomMargin: 8; left: parent.left; right: parent.right }
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: list
            width: parent.width
            spacing: 4
            Repeater {
                model: ScriptModel { values: root.nodes }
                ListRow {
                    id: device
                    required property var modelData
                    readonly property bool chosen: modelData === root.current
                    width: list.width
                    selected: chosen
                    icon: root.icon(modelData)
                    title: modelData.description || modelData.nickname || modelData.name
                    subtitle: modelData.name.includes("bluez") ? "Bluetooth" : chosen ? "Default" : ""
                    Icon { name: device.chosen ? "radio_button_checked" : "radio_button_unchecked"; filled: true; color: device.chosen ? device.content : Theme.onSurfaceVariantColor }
                    onClicked: {
                        if (root.sinks) Pipewire.preferredDefaultAudioSink = modelData;
                        else Pipewire.preferredDefaultAudioSource = modelData;
                    }
                }
            }
        }
    }

    TextButton {
        id: footer
        anchors.bottom: parent.bottom
        text: "Sound settings"
        icon: "open_in_new"
        onClicked: { Panels.close(); Controls.run(["pavucontrol", "-t", root.sinks ? "3" : "4"]); }
    }
}
