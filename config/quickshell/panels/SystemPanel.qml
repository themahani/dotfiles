import QtQuick
import Quickshell
import "../components"
import "../services"
import "../theme"

// Quick settings: battery and power, sliders, tiles and system monitor.
// Chevrons slide in detail pages inside the same panel.
Item {
    id: root
    property string page: "home"        // "home", "wifi", "bluetooth", "output" or "input"
    property bool powerOpen: false
    implicitWidth: 400
    implicitHeight: Math.max(home.implicitHeight + 32, 560)

    readonly property var pages: ({ wifi: wifiPage, bluetooth: bluetoothPage, output: outputPage, input: inputPage })
    function open(name) { page = name; }
    function showRequestedPage() {
        if (Panels.page === "power") powerOpen = true;
        else if (pages[Panels.page]) page = Panels.page;
        Panels.page = "";
    }
    Component.onCompleted: showRequestedPage()
    // A page asked for while the panel is already open, e.g. a pairing request.
    Connections {
        target: Panels
        function onPageChanged() { if (Panels.page !== "") root.showRequestedPage(); }
    }

    Column {
        id: home
        visible: root.page === "home"
        x: 16; y: 16
        width: parent.width - 32
        spacing: 16

        Item {
            width: parent.width
            height: 48
            Rectangle {
                id: badge
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: Theme.surfaceContainerHighest
                Icon {
                    id: badgeIcon
                    anchors.centerIn: parent
                    name: Power.hasBattery ? Power.icon : "computer"
                    filled: true
                    color: Power.low ? Theme.error : Theme.onSurfaceColor
                    SequentialAnimation on opacity {
                        running: Power.low
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 1500 }
                        NumberAnimation { to: 1; duration: 1500 }
                        onRunningChanged: if (!running) badgeIcon.opacity = 1
                    }
                }
            }
            Column {
                anchors { left: badge.right; leftMargin: 12; right: powerButton.left; verticalCenter: parent.verticalCenter }
                spacing: 2
                StyledText {
                    width: parent.width
                    text: Power.hasBattery ? Power.level + "%" : "System"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: Power.low ? Theme.error : Theme.onSurfaceColor
                }
                StyledText {
                    width: parent.width
                    text: [Power.status, Power.profileName + " profile"].filter(Boolean).join(" · ")
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: Theme.onSurfaceVariantColor
                }
            }
            IconButton {
                id: powerButton
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                color: Theme.surfaceContainerHighest
                icon: "power_settings_new"
                tooltip: "Power"
                onClicked: root.powerOpen = true
            }
        }

        Column {
            width: parent.width
            spacing: 8
            PillSlider {
                visible: Metrics.data.brightness >= 0
                width: parent.width
                name: "Brightness"
                icon: "brightness_6"
                value: Controls.brightnessValue / 100
                onMoved: value => Controls.setBrightness(Math.max(5, value * 100))
            }
            Repeater {
                model: [
                    { node: Controls.sink, name: "Volume", page: "output", icons: ["volume_off", "volume_down", "volume_up"] },
                    { node: Controls.source, name: "Microphone", page: "input", icons: ["mic_off", "mic", "mic"] }
                ]
                Row {
                    id: audioRow
                    required property var modelData
                    readonly property var audio: modelData.node ? modelData.node.audio : null
                    readonly property real level: audio ? audio.volume : 0
                    readonly property bool muted: !audio || audio.muted
                    width: parent.width
                    spacing: 8
                    PillSlider {
                        width: parent.width - 56
                        name: audioRow.modelData.name
                        value: audioRow.muted ? 0 : Math.min(1, audioRow.level)
                        label: audioRow.muted ? "Muted" : Math.round(audioRow.level * 100) + "%"
                        icon: audioRow.modelData.icons[audioRow.muted || audioRow.level === 0 ? 0 : audioRow.level < 0.4 ? 1 : 2]
                        onMoved: value => {
                            if (!audioRow.audio) return;
                            audioRow.audio.muted = false;
                            audioRow.audio.volume = value;
                        }
                    }
                    IconButton {
                        width: 48; height: 48
                        color: Theme.surfaceContainerHighest
                        icon: "chevron_right"
                        tooltip: audioRow.modelData.name === "Volume" ? "Output device" : "Input device"
                        onClicked: root.open(audioRow.modelData.page)
                    }
                }
            }
        }

        Grid {
            width: parent.width
            columns: 2
            columnSpacing: 8
            rowSpacing: 8
            readonly property real cell: (width - columnSpacing) / 2
            Tile {
                width: parent.cell
                icon: Network.icon === "lan" || Network.icon === "airplanemode_active" ? Network.icon
                    : Network.wifiEnabled ? (Network.network ? "wifi" : "wifi_find") : "wifi_off"
                label: "Internet"
                subtitle: Network.label
                active: !Network.airplane && (Network.wiredConnected || Network.wifiEnabled)
                hasDetails: true
                onToggled: Network.setWifi(!Network.wifiEnabled || Network.airplane)
                onDetails: root.open("wifi")
            }
            Tile {
                width: parent.cell
                icon: Network.bluetoothIcon
                label: "Bluetooth"
                subtitle: Network.bluetoothLabel
                active: Network.bluetoothEnabled
                hasDetails: true
                onToggled: { if (Network.adapter) Network.adapter.enabled = !Network.adapter.enabled; }
                onDetails: root.open("bluetooth")
            }
            Tile {
                width: parent.cell
                icon: "coffee"
                label: "Stay awake"
                subtitle: Controls.idleInhibited ? "Idle won't lock" : "Off"
                active: Controls.idleInhibited
                onToggled: Controls.idleInhibited = !Controls.idleInhibited
            }
            Tile {
                width: parent.cell
                icon: "airplanemode_active"
                label: "Airplane mode"
                subtitle: Network.airplane ? "On" : "Off"
                active: Network.airplane
                onToggled: Controls.setAirplane(!Network.airplane)
            }
            Tile {
                width: parent.cell
                icon: Power.profileIcon
                label: "Power profile"
                subtitle: Power.profileName
                active: Power.profileChanged
                onToggled: Power.cycleProfile()
            }
            Tile {
                width: parent.cell
                icon: "desktop_access_disabled"
                label: "Screen off"
                subtitle: "Any input wakes"
                onToggled: { Panels.close(); Controls.screenOff(); }
            }
        }

        Grid {
            width: parent.width
            columns: 4
            columnSpacing: 8
            readonly property real cell: (width - columnSpacing * 3) / 4
            Repeater {
                // A fixed model keeps the cards (and their hover) across metric updates.
                model: ["CPU", "RAM", "DISK", "TEMP"]
                Rectangle {
                    required property string modelData
                    readonly property string label: modelData
                    readonly property string value: label === "CPU" ? Metrics.data.cpu + "%"
                        : label === "RAM" ? Metrics.data.memoryUsed.toFixed(1) + "G"
                        : label === "DISK" ? Metrics.data.diskPercent + "%"
                        : Metrics.data.temperature >= 0 ? Metrics.data.temperature + "°C" : "—"
                    readonly property var values: (label === "CPU" ? Metrics.history.cpu : label === "RAM" ? Metrics.history.memory
                        : label === "DISK" ? Metrics.history.disk : Metrics.history.temperature).slice(-20)
                    width: parent.cell
                    height: 92
                    radius: 16
                    color: Theme.surfaceContainerHigh
                    Column {
                        x: 12; y: 10
                        width: parent.width - 24
                        StyledText { text: parent.parent.label; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 0.6; color: Theme.onSurfaceVariantColor }
                        StyledText { text: parent.parent.value; font.pixelSize: 17; font.weight: Font.DemiBold }
                    }
                    Sparkline {
                        x: 12; y: parent.height - height - 10
                        width: parent.width - 24; height: 26
                        values: parent.values
                        minimum: parent.label === "TEMP" ? Math.min.apply(null, parent.values.concat([30])) : 0
                        maximum: 100
                    }
                    StateLayer { onClicked: { Panels.close(); Controls.btop(); } }
                    Accessible.role: Accessible.Button
                    Accessible.name: label + " " + value + ", open btop"
                }
            }
        }
    }

    Loader {
        id: pageLoader
        x: 16; y: 16
        width: parent.width - 32
        height: parent.height - 32
        active: root.page !== "home"
        sourceComponent: root.pages[root.page] || null
        onLoaded: slideIn.restart()
        ParallelAnimation {
            id: slideIn
            NumberAnimation { target: pageLoader; property: "x"; from: 44; to: 16; duration: Theme.durationMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
            NumberAnimation { target: pageLoader.item; property: "opacity"; from: 0; to: 1; duration: Theme.durationShort }
        }
    }

    PowerSheet {
        anchors.fill: parent
        open: root.powerOpen
        onClose: root.powerOpen = false
    }

    Component { id: wifiPage; WifiPage { onBack: root.page = "home" } }
    Component { id: bluetoothPage; BluetoothPage { onBack: root.page = "home" } }
    Component { id: outputPage; AudioDevicesPage { sinks: true; onBack: root.page = "home" } }
    Component { id: inputPage; AudioDevicesPage { sinks: false; onBack: root.page = "home" } }
}
