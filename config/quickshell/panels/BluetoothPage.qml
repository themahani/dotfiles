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
            StyledText {
                visible: root.paired.length > 0
                leftPadding: 8; topPadding: 4; bottomPadding: 4
                text: "Paired devices"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.primary
            }
            Repeater {
                model: root.paired
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
                model: root.found
                ListRow {
                    id: candidate
                    required property var modelData
                    width: list.width
                    circle: true
                    iconFilled: false
                    icon: Network.deviceIcon(modelData.icon)
                    title: modelData.name
                    subtitle: modelData.pairing ? "Pairing…" : "Click to pair"
                    Spinner { visible: candidate.modelData.pairing; size: 20 }
                    onClicked: if (!modelData.pairing) modelData.pair()
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
