import QtQuick
import Quickshell
import Quickshell.Networking as Net
import "../components"
import "../services"
import "../theme"

// Networks in range. Saved ones connect in one click; a new secured network
// asks for its password inline; right-click a saved one to forget it.
Item {
    id: root
    signal back()
    property string expanded: ""        // network asking for a password
    property string managing: ""        // saved network showing forget/disconnect
    property string failure: ""
    readonly property var device: Network.wifi
    readonly property var networks: device ? device.networks.values.slice().sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)) : []

    Component.onCompleted: if (device) device.scannerEnabled = true
    Component.onDestruction: if (device) device.scannerEnabled = false

    PageHeader {
        id: header
        width: parent.width
        title: "Internet"
        onBack: root.back()
        ToggleSwitch {
            label: "Wi-Fi"
            checked: Network.wifiEnabled && !Network.airplane
            onToggled: Network.setWifi(!checked)
        }
    }

    Flickable {
        id: networks
        anchors { top: header.bottom; topMargin: 8; bottom: footer.top; bottomMargin: 8; left: parent.left; right: parent.right }
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: list
            width: parent.width
            spacing: 4
            ListRow {
                visible: Network.wiredConnected
                width: parent.width
                icon: "lan"
                title: "Ethernet"
                subtitle: "Connected"
                selected: true
            }
            Repeater {
                model: Network.wifiEnabled && !Network.airplane ? root.networks : []
                Rectangle {
                    id: entry
                    required property var modelData
                    readonly property bool secured: modelData.security !== Net.WifiSecurityType.Open
                    readonly property bool asking: root.expanded === modelData.name && !modelData.known
                    width: list.width
                    height: row.height + (asking || managing.visible ? extra.implicitHeight + 12 : 0)
                    radius: 16
                    color: modelData.connected ? Theme.primaryContainer : "transparent"
                    Behavior on height { NumberAnimation { duration: Theme.durationShort } }
                    clip: true
                    readonly property Item managing: manage
                    Connections {
                        target: entry.modelData
                        function onConnectionFailed(reason) {
                            root.failure = entry.modelData.name + ": " + Net.ConnectionFailReason.toString(reason);
                        }
                    }
                    ListRow {
                        id: row
                        width: parent.width
                        color: "transparent"
                        selected: entry.modelData.connected
                        icon: Network.signalIcon(entry.modelData.signalStrength)
                        title: entry.modelData.name
                        subtitle: entry.modelData.stateChanging ? "Connecting…" : entry.modelData.connected ? "Connected"
                            : entry.modelData.known ? "Saved" : entry.secured ? "Secured" : "Open"
                        Icon { visible: entry.secured; name: "lock"; size: 16; color: row.content; opacity: 0.7 }
                        Spinner { visible: entry.modelData.stateChanging; size: 18; color: row.content }
                        onClicked: button => {
                            root.failure = "";
                            const network = entry.modelData;
                            if (button === Qt.RightButton) { root.managing = network.known ? network.name : ""; return; }
                            root.managing = "";
                            if (network.connected || network.stateChanging) return;
                            if (network.known || !entry.secured) network.connect();
                            else root.expanded = root.expanded === network.name ? "" : network.name;
                        }
                    }
                    Item {
                        id: extra
                        anchors { top: row.bottom; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                        implicitHeight: 40
                        Row {
                            visible: entry.asking
                            anchors.fill: parent
                            spacing: 8
                            TextField {
                                id: password
                                width: parent.width - connect.width - 8
                                placeholder: "Password"
                                echoMode: TextInput.Password
                                onAccepted: connect.clicked()
                                onVisibleChanged: if (visible) focusInput()
                            }
                            TextButton {
                                id: connect
                                implicitHeight: 40
                                style: "filled"
                                text: "Connect"
                                onClicked: {
                                    if (!password.text) return;
                                    entry.modelData.connectWithPsk(password.text);
                                    password.text = "";
                                    root.expanded = "";
                                }
                            }
                        }
                        Row {
                            id: manage
                            visible: root.managing === entry.modelData.name
                            anchors.right: parent.right
                            spacing: 8
                            TextButton { text: "Cancel"; onClicked: root.managing = "" }
                            TextButton {
                                visible: entry.modelData.connected
                                style: "outlined"
                                text: "Disconnect"
                                onClicked: { entry.modelData.disconnect(); root.managing = ""; }
                            }
                            TextButton {
                                style: "danger"
                                text: "Forget"
                                onClicked: { entry.modelData.forget(); root.managing = ""; }
                            }
                        }
                    }
                }
            }
            StyledText {
                visible: root.failure !== ""
                width: parent.width
                leftPadding: 16
                text: "Couldn't connect to " + root.failure
                color: Theme.error
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
            StyledText {
                visible: root.networks.length > 0 && Network.wifiEnabled && !Network.airplane
                leftPadding: 16
                topPadding: 6
                text: "Right-click a saved network to forget it."
                font.pixelSize: 12
                font.weight: Font.Normal
                color: Theme.onSurfaceVariantColor
            }
        }
        Column {
            parent: networks       // the content item has no height when empty
            anchors.centerIn: parent
            visible: !Network.wifiEnabled || Network.airplane || !root.device
            spacing: 10
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Network.airplane ? "airplanemode_active" : "wifi_off"; size: 32; color: Theme.onSurfaceVariantColor }
            StyledText {
                text: !root.device ? "No Wi-Fi device" : Network.airplane ? "Airplane mode is on" : "Wi-Fi is off"
                color: Theme.onSurfaceVariantColor
                font.weight: Font.Normal
            }
        }
    }

    TextButton {
        id: footer
        anchors.bottom: parent.bottom
        text: "Network settings"
        icon: "open_in_new"
        onClicked: { Panels.close(); Controls.run(["nm-connection-editor"]); }
    }
}
