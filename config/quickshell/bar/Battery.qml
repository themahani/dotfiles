import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../services"
import "../theme"

Chip {
    id: root
    property bool timeMode: false
    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge
    readonly property int capacity: Math.round(battery.percentage * 100)
    readonly property bool critical: capacity <= 15 && !plugged
    readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string remaining: {
        const seconds = charging ? battery.timeToFull : battery.timeToEmpty;
        return seconds > 0 ? Math.floor(seconds / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "min" : "Unknown";
    }
    visible: battery.ready && battery.isLaptopBattery && battery.isPresent
    foreground: critical ? Theme.text : Theme.green
    color: critical ? Theme.red : "transparent"
    text: (charging ? "" : plugged ? "󱘖" : icons[Math.min(10, Math.floor(capacity / 10))]) + " "
        + (timeMode ? remaining : capacity >= 100 ? "Full" : capacity + "%")
    tooltip: (charging ? "Time to full: " : "Time to empty: ") + remaining + " | " + Math.abs(battery.changeRate).toFixed(1) + "W"
    SequentialAnimation on opacity {
        running: root.critical; loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 1500 }
        NumberAnimation { to: 1; duration: 1500 }
    }
    onCriticalChanged: if (!critical) opacity = 1
    onClicked: button => {
        if (button === Qt.RightButton) Controls.hyprScript("Wlogout.sh", "");
        else timeMode = !timeMode;
    }
}
