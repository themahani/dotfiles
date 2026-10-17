import QtQuick
import Quickshell.Bluetooth as Blue
import Quickshell.Networking as Net
import Quickshell.Services.UPower
import "../components"
import "../services"
import "../theme"

// Status icons; the whole group opens the system panel and scrolls volume.
BarButton {
    id: root
    required property var screen
    readonly property var wifi: Net.Networking.devices.values.find(item => item.type === Net.DeviceType.Wifi) || null
    readonly property var wired: Net.Networking.devices.values.find(item => item.type === Net.DeviceType.Wired && item.connected) || null
    readonly property var network: wifi ? wifi.networks.values.find(item => item.connected) || null : null
    readonly property var adapter: Blue.Bluetooth.defaultAdapter
    readonly property bool btConnected: Blue.Bluetooth.devices.values.some(item => item.connected)
    readonly property var sink: Controls.sink
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.ready && battery.isLaptopBattery && battery.isPresent
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || hasBattery && (battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
    readonly property int level: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool low: hasBattery && level <= 15 && !plugged

    open: Panels.isOpen("system", screen)
    tooltip: "System"
    spacing: 10
    padding: 12
    onClicked: Panels.toggle("system", screen)
    onScrolled: direction => Controls.volume(direction > 0 ? "inc" : "dec", false)

    Icon { visible: Controls.idleInhibited; name: "coffee"; filled: true; size: 18; color: Theme.primary }
    Icon { visible: Notifications.dnd; name: "do_not_disturb_on"; filled: true; size: 18; color: Theme.primary }
    Icon {
        size: 18
        filled: true
        name: Metrics.data.airplane ? "airplanemode_active" : root.wired ? "lan"
            : root.network ? ["network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"][Math.min(3, Math.floor(root.network.signalStrength * 4))]
            : Net.Networking.wifiEnabled && root.wifi ? "signal_wifi_0_bar" : "wifi_off"
    }
    Icon {
        size: 18
        name: !root.adapter || !root.adapter.enabled ? "bluetooth_disabled" : root.btConnected ? "bluetooth_connected" : "bluetooth"
    }
    Icon {
        size: 18
        filled: true
        name: root.muted || root.volume === 0 ? "volume_off" : root.volume < 40 ? "volume_down" : "volume_up"
    }
    Row {
        id: batteryRow
        visible: root.hasBattery
        spacing: 2
        Icon {
            size: 18
            filled: true
            color: root.low ? Theme.error : Theme.onSurface
            name: root.charging ? "battery_charging_full" : root.level >= 95 ? "battery_full"
                : "battery_" + Math.min(6, Math.floor(root.level / 14)) + "_bar"
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.level + "%"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.low ? Theme.error : Theme.onSurface
        }
        SequentialAnimation on opacity {
            running: root.low
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 1500 }
            NumberAnimation { to: 1; duration: 1500 }
            onRunningChanged: if (!running) batteryRow.opacity = 1
        }
    }
}
