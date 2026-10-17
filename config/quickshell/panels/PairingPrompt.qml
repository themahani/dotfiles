import QtQuick
import "../components"
import "../services"
import "../theme"

// The pairing agent's pending request, laid out like the Wi-Fi password row:
// a code to compare or type, or a field for the PIN, and the answer buttons.
Column {
    id: root
    property string device: ""          // the device's name, when it is known
    readonly property string type: BluetoothAgent.type
    readonly property string subject: device || "the device"
    readonly property bool entering: type === "pin" || type === "passkey"
    // Names for the services devices usually ask for, by 16-bit UUID.
    readonly property var services: ({ "1105": "file transfer", "1108": "headset audio", "110a": "audio playback",
        "110b": "audio playback", "110c": "media controls", "110e": "media controls", "1112": "headset audio",
        "111e": "hands-free calls", "111f": "hands-free calls", "1124": "keyboard or mouse input", "112f": "contacts" })
    readonly property string serviceName: {
        const uuid = BluetoothAgent.service.toLowerCase();
        const short = /^0000([0-9a-f]{4})-0000-1000-8000-00805f9b34fb$/.exec(uuid);
        return short && services[short[1]] ? services[short[1]] : uuid;
    }
    spacing: 8

    StyledText {
        width: parent.width
        wrapMode: Text.Wrap
        font.pixelSize: 13
        font.weight: Font.Normal
        color: Theme.onSurfaceVariantColor
        text: root.type === "confirm" ? "Pair only if " + root.subject + " shows the same code."
            : root.type === "pin" ? "Enter the PIN for " + root.subject + "."
            : root.type === "passkey" ? "Enter the passkey shown on " + root.subject + "."
            : root.type.startsWith("display") ? "Type this code on " + root.subject + ", then press Enter."
            : root.type === "pairing" ? (root.device || "A device") + " wants to pair."
            : root.type === "service" ? (root.device || "A paired device") + " wants to use " + root.serviceName + "."
            : ""
    }
    StyledText {
        visible: BluetoothAgent.code !== ""
        text: BluetoothAgent.code
        font.pixelSize: 28
        font.weight: Font.DemiBold
        font.letterSpacing: 4
    }
    Row {
        visible: root.entering
        width: parent.width
        spacing: 8
        TextField {
            id: entry
            width: parent.width - send.width - 8
            placeholder: root.type === "pin" ? "PIN" : "Passkey"
            onAccepted: send.clicked()
            onVisibleChanged: if (visible) { text = ""; focusInput(); }
        }
        TextButton {
            id: send
            implicitHeight: 40
            style: "filled"
            text: "Pair"
            onClicked: {
                if (!entry.text) return;
                BluetoothAgent.respond(entry.text);
                entry.text = "";
            }
        }
    }
    Row {
        anchors.right: parent.right
        spacing: 8
        TextButton {
            text: root.type === "pairing" || root.type === "service" ? "Deny" : "Cancel"
            onClicked: BluetoothAgent.cancel()
        }
        TextButton {
            visible: root.type === "confirm" || root.type === "pairing" || root.type === "service"
            style: "filled"
            text: root.type === "confirm" ? "Pair" : "Allow"
            onClicked: BluetoothAgent.respond("yes")
        }
    }
}
