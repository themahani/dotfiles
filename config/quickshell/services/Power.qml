pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery state shared by the bar and the system panel.
Singleton {
    id: root
    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device !== null && device.ready && device.isLaptopBattery && device.isPresent
    readonly property bool charging: hasBattery && device.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || hasBattery && (device.state === UPowerDeviceState.FullyCharged
        || device.state === UPowerDeviceState.PendingCharge)
    readonly property int level: hasBattery ? Math.round(device.percentage * 100) : 0
    readonly property bool low: hasBattery && level <= 15 && !plugged
    readonly property string icon: charging ? "battery_charging_full" : level >= 95 ? "battery_full"
        : "battery_" + Math.min(6, Math.floor(level / 14)) + "_bar"
    readonly property string status: {
        if (!hasBattery) return "";
        if (charging) return device.timeToFull > 0 ? duration(device.timeToFull) + " to full" : "Charging";
        if (plugged) return "Plugged in";
        return device.timeToEmpty > 0 ? duration(device.timeToEmpty) + " left" : low ? "Battery low" : "On battery";
    }
    function duration(seconds) {
        const minutes = Math.round(seconds / 60);
        return minutes >= 60 ? Math.floor(minutes / 60) + "h " + (minutes % 60) + "m" : minutes + "m";
    }

    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced]
        .concat(PowerProfiles.hasPerformanceProfile ? [PowerProfile.Performance] : [])
    readonly property string profileName: PowerProfiles.profile === PowerProfile.Performance ? "Performance"
        : PowerProfiles.profile === PowerProfile.PowerSaver ? "Power saver" : "Balanced"
    readonly property string profileIcon: PowerProfiles.profile === PowerProfile.Performance ? "speed"
        : PowerProfiles.profile === PowerProfile.PowerSaver ? "eco" : "balance"
    readonly property bool profileChanged: PowerProfiles.profile !== PowerProfile.Balanced
    function cycleProfile() {
        PowerProfiles.profile = profiles[(profiles.indexOf(PowerProfiles.profile) + 1) % profiles.length];
    }
}
