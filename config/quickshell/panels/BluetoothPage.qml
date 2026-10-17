import QtQuick
import Quickshell
import Quickshell.Bluetooth as Blue
import "../components"
import "../services"
import "../theme"

// Paired devices first; scans for new ones while the page is open.
Item {
    id: root
    signal back()
    readonly property var adapter: Network.adapter
    readonly property var devices: Blue.Bluetooth.devices.values
    readonly property var paired: devices.filter(item => item.paired || item.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var found: devices.filter(item => !item.paired && !item.bonded && item.deviceName)
    // A request for a device being paired from this page shows under its row;
    // any other (a phone pairing with us, a service request) shows on top.
    readonly property bool requestOnTop: BluetoothAgent.type !== "" && !found.some(item => item.pairing)

    Component.onCompleted: if (adapter && adapter.enabled) adapter.discovering = true
    Component.onDestruction: if (adapter) adapter.discovering = false
    Connections {
        target: root.adapter
        function onEnabledChanged() { if (root.adapter.enabled) root.adapter.discovering = true; }
    }

    PageHeader {
        id: header
        width: parent.width
        title: "Bluetooth"
        onBack: root.back()
        ToggleSwitch {
            label: "Bluetooth"
            checked: Network.bluetoothEnabled
            onToggled: { if (root.adapter) root.adapter.enabled = !checked; }
        }
    }

    Flickable {
        anchors { top: header.bottom; topMargin: 8; bottom: footer.top; bottomMargin: 8; left: parent.left; right: parent.right }
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: Network.bluetoothEnabled
        Column {
            id: list
            width: parent.width
            Rectangle {
                visible: root.requestOnTop
                width: list.width
                height: visible ? request.implicitHeight + 24 : 0
                radius: 16
                color: Theme.surfaceContainerHigh
                PairingPrompt { id: request; x: 12; y: 12; width: parent.width - 24 }
            }
            Item { visible: root.requestOnTop; width: 1; height: 8 }
            StyledText {
                visible: root.paired.length > 0
                leftPadding: 8; topPadding: 4; bottomPadding: 4
                text: "Paired devices"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.primary
            }
            Repeater {
                model: ScriptModel { values: root.paired }
                ListRow {
                    id: device
                    required property var modelData
                    readonly property bool busy: modelData.state === Blue.BluetoothDeviceState.Connecting
                        || modelData.state === Blue.BluetoothDeviceState.Disconnecting
                    width: list.width
                    circle: true
                    icon: Network.deviceIcon(modelData.icon)
                    iconBackground: modelData.connected ? Theme.primary : Theme.surfaceContainerHighest
                    iconColor: modelData.connected ? Theme.onPrimaryColor : Theme.onSurfaceColor
                    title: modelData.name
                    subtitle: busy ? (modelData.connected ? "Disconnecting…" : "Connecting…")
                        : modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "% battery" : "")
                        : "Not connected"
                    Spinner { visible: device.busy; size: 20 }
                    TextButton {
                        visible: !device.busy
                        style: device.modelData.connected ? "outlined" : "tonal"
                        text: device.modelData.connected ? "Disconnect" : "Connect"
                        onClicked: device.modelData.connected ? device.modelData.disconnect() : device.modelData.connect()
                    }
                }
            }
            Row {
                leftPadding: 8; topPadding: 16; bottomPadding: 4
                spacing: 8
                StyledText { text: "Pair new device"; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.primary }
                Spinner { visible: root.adapter !== null && root.adapter.discovering; size: 14; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            }
            Repeater {
                model: ScriptModel { values: root.found }
                Rectangle {
                    id: candidate
                    required property var modelData
                    readonly property bool asking: modelData.pairing && BluetoothAgent.type !== ""
                    width: list.width
                    height: row.height + (asking ? prompt.implicitHeight + 12 : 0)
                    radius: 16
                    color: asking ? Theme.surfaceContainerHigh : "transparent"
                    clip: true
                    Behavior on height { NumberAnimation { duration: Theme.durationShort } }
                    ListRow {
                        id: row
                        width: parent.width
                        color: "transparent"
                        circle: true
                        iconFilled: false
                        icon: Network.deviceIcon(candidate.modelData.icon)
                        title: candidate.modelData.name
                        // Without the agent, bluez would pair without asking for any code.
                        subtitle: candidate.modelData.pairing ? "Pairing…" : BluetoothAgent.ready ? "Click to pair" : "Pairing unavailable"
                        Spinner { visible: candidate.modelData.pairing; size: 20 }
                        onClicked: if (!candidate.modelData.pairing && BluetoothAgent.ready) candidate.modelData.pair()
                    }
                    PairingPrompt {
                        id: prompt
                        visible: candidate.asking
                        device: candidate.modelData.name
                        anchors { top: row.bottom; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                    }
                    Connections {
                        target: candidate.modelData
                        function onPairedChanged() {
                            if (!candidate.modelData.paired) return;
                            candidate.modelData.trusted = true;
                            candidate.modelData.connect();
                        }
                    }
                }
            }
            StyledText {
                visible: root.found.length === 0
                leftPadding: 8; topPadding: 4
                text: "Searching for nearby devices…"
                font.pixelSize: 13
                font.weight: Font.Normal
                color: Theme.onSurfaceVariantColor
            }
        }
    }
    Column {
        anchors.centerIn: parent
        visible: !Network.bluetoothEnabled
        spacing: 10
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bluetooth_disabled"; size: 32; color: Theme.onSurfaceVariantColor }
        StyledText { text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter"; color: Theme.onSurfaceVariantColor; font.weight: Font.Normal }
    }

    TextButton {
        id: footer
        anchors.bottom: parent.bottom
        text: "Bluetooth settings"
        icon: "open_in_new"
        onClicked: { Panels.close(); Controls.run(["blueberry"]); }
    }
}
