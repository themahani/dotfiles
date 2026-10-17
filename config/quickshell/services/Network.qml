pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth as Blue
import Quickshell.Networking as Net

// Network and Bluetooth summaries shared by the bar and the system panel.
Singleton {
    id: root
    readonly property var wifi: Net.Networking.devices.values.find(item => item.type === Net.DeviceType.Wifi) || null
    readonly property var wired: Net.Networking.devices.values.find(item => item.type === Net.DeviceType.Wired) || null
    readonly property bool wiredConnected: wired !== null && wired.connected
    readonly property var network: wifi ? wifi.networks.values.find(item => item.connected) || null : null
    readonly property bool wifiEnabled: Net.Networking.wifiEnabled
    readonly property bool airplane: Metrics.data.airplane
    readonly property string icon: airplane ? "airplanemode_active" : wiredConnected ? "lan"
        : network ? signalIcon(network.signalStrength)
        : wifiEnabled && wifi ? "signal_wifi_0_bar" : "wifi_off"
    readonly property string label: airplane ? "Airplane mode" : wiredConnected ? "Ethernet"
        : network ? network.name : !wifi ? "No Wi-Fi device" : wifiEnabled ? "Not connected" : "Off"
    function setWifi(enabled) {
        if (enabled && airplane) Controls.setAirplane(false);
        Net.Networking.wifiEnabled = enabled;
    }
    function signalIcon(strength) {
        return ["network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"][Math.min(3, Math.floor(strength * 4))];
    }

    readonly property var adapter: Blue.Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: adapter !== null && adapter.enabled
    readonly property var bluetoothConnected: Blue.Bluetooth.devices.values.filter(item => item.connected)
    readonly property string bluetoothIcon: !bluetoothEnabled ? "bluetooth_disabled" : bluetoothConnected.length ? "bluetooth_connected" : "bluetooth"
    readonly property string bluetoothLabel: !adapter ? "No adapter" : !bluetoothEnabled ? "Off"
        : bluetoothConnected.length === 1 ? bluetoothConnected[0].name
        : bluetoothConnected.length ? bluetoothConnected.length + " connected" : "On"
    function deviceIcon(name) {
        name = (name || "").toLowerCase();
        if (/headset|headphone|audio-head/.test(name)) return "headphones";
        if (/keyboard/.test(name)) return "keyboard";
        if (/mouse|pointing/.test(name)) return "mouse";
        if (/phone/.test(name)) return "smartphone";
        if (/speaker|audio-card|audio/.test(name)) return "speaker";
        if (/gaming|joystick|gamepad/.test(name)) return "sports_esports";
        if (/computer|laptop/.test(name)) return "computer";
        if (/watch/.test(name)) return "watch";
        return "bluetooth";
    }
}
