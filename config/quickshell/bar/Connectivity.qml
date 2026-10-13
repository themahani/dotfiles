import QtQuick
import Quickshell.Networking as Net
import Quickshell.Bluetooth as Blue
import "../components"
import "../services"
import "../theme"

Row {
    readonly property var device: Net.Networking.devices.values.find(item => item.connected && item.type === Net.DeviceType.Wired)
        || Net.Networking.devices.values.find(item => item.connected) || null
    readonly property var network: device ? device.networks.values.find(item => item.connected) || null : null
    readonly property var connected: Blue.Bluetooth.devices.values.filter(item => item.connected)
    readonly property var statistics: device ? Metrics.data.interfaces[device.name] || {} : {}
    function rate(value) { return value >= 1000000 ? (value / 1000000).toFixed(1) + " Mb/s" : ((value || 0) / 1000).toFixed(1) + " kb/s"; }
    Chip {
        foreground: device ? Theme.teal : Theme.text
        text: !device ? "󰌙" : !statistics.ip ? "󰈁 " + device.name + " (No IP)" : device.type === Net.DeviceType.Wifi ?
            ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor((network ? network.signalStrength : 0) * 4))] : "󰌘"
        tooltip: !device ? "Disconnected" : device.name + " " + (network ? network.name : "")
            + (device.type === Net.DeviceType.Wifi && network ? " " + Math.round(network.signalStrength * 100) + "%" : "")
            + "\n" + (statistics.ip || "No IP") + "  " + rate(statistics.up) + "  " + rate(statistics.down)
        onClicked: button => { if (button === Qt.RightButton) Controls.run(["nm-connection-editor"]); }
    }
    Chip {
        foreground: Theme.blue
        text: connected.length ? "󰂱 " + connected.length : Blue.Bluetooth.defaultAdapter && Blue.Bluetooth.defaultAdapter.enabled ? "" : "󰂳"
        tooltip: connected.length ? connected.map(item => item.name + (item.batteryAvailable ? " 󰂄" + Math.round(item.battery * 100) + "%" : "")).join("\n") : "Bluetooth"
        onClicked: Controls.run(["blueberry"])
    }
}
