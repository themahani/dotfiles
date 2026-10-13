import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../services"
import "../theme"

Row {
    spacing: 0
    Chip {
        text: Controls.idleInhibited ? "" : ""
        foreground: Controls.idleInhibited ? Theme.idleActive : Theme.text
        tooltip: Controls.idleInhibited ? "Idle inhibitor active" : "Idle inhibitor not active"
        onClicked: Controls.idleInhibited = !Controls.idleInhibited
    }
    Chip {
        text: "󰶐"
        tooltip: "Turn off screens (any input wakes them)\n" + (Controls.idleInhibited
            ? "Idle inhibitor active: system stays awake" : "Idle timers still apply: lock and suspend")
        onClicked: Controls.screenOff()
    }
    Chip {
        textFormat: Text.RichText
        text: (Notifications.dnd ? "" : "") + (Notifications.count ? " <font color='" + Theme.red + "'>•</font> " + Notifications.count : "")
        tooltip: "Left: notification center · Right: do not disturb"
        onClicked: button => {
            if (button === Qt.RightButton) Notifications.dnd = !Notifications.dnd;
            else Notifications.centerOpen = !Notifications.centerOpen;
        }
    }
    Chip {
        text: " " + Metrics.data.keyboard.slice(0, 3).toUpperCase()
        tooltip: Metrics.data.keyboard
        onClicked: { if (Metrics.data.keyboardName) Controls.run(["hyprctl", "switchxkblayout", Metrics.data.keyboardName, "next"]); }
    }
    Chip { text: "|" }
    Chip {
        property bool graph: false
        text: (graph ? Metrics.data.cores.slice(0, 4).map(value => "▁▂▃▄▅▆▇█"[Math.min(7, Math.floor(value / 12.5))]).join("") + " " : "") + Metrics.data.cpu + "% 󰍛"
        foreground: Theme.green
        tooltip: "CPU " + Metrics.data.cores.map((value, index) => index + ": " + value + "%").join(" · ")
        onClicked: button => { if (button === Qt.RightButton) Controls.run(["kitty", "-e", "btop"]); else graph = !graph; }
    }
    Chip {
        property bool percentage: false
        text: (percentage ? Metrics.data.memoryPercent + "%" : Metrics.data.memoryUsed.toFixed(1) + "G") + " 󰾆"
        foreground: Theme.sky
        tooltip: Metrics.data.memoryUsed.toFixed(1) + "GB/" + Metrics.data.memoryTotal.toFixed(1) + "G"
        onClicked: button => { if (button === Qt.RightButton) Controls.run(["kitty", "-e", "btop"]); else percentage = !percentage; }
    }
    Chip {
        text: Metrics.data.diskPercent + "% 󰋊"
        foreground: Theme.sapphire
        tooltip: Metrics.data.diskUsed + " used out of " + Metrics.data.diskTotal + " on /"
    }
    Chip {
        text: PowerProfiles.profile === PowerProfile.Performance ? "" : PowerProfiles.profile === PowerProfile.PowerSaver ? "" : ""
        readonly property string profileName: PowerProfiles.profile === PowerProfile.Performance ? "performance"
            : PowerProfiles.profile === PowerProfile.PowerSaver ? "power-saver" : "balanced"
        tooltip: "Power profile: " + profileName + "\nDriver: " + (Metrics.data.profileDrivers[profileName] || "Unavailable")
        onClicked: {
            const profiles = [PowerProfile.PowerSaver, PowerProfile.Balanced];
            if (PowerProfiles.hasPerformanceProfile) profiles.push(PowerProfile.Performance);
            PowerProfiles.profile = profiles[(profiles.indexOf(PowerProfiles.profile) + 1) % profiles.length];
        }
    }
    Chip { text: "|" }
    Chip {
        visible: Metrics.data.brightness >= 0
        text: ["", "", "", "󰃝", "󰃞", "󰃟", "󰃠"][Math.min(6, Math.floor(Math.max(0, Metrics.data.brightness) * 6 / 100))]
        foreground: Theme.blue
        tooltip: "Backlight " + Metrics.data.brightness + "%"
        onScrolled: direction => Controls.brightness(direction > 0 ? "inc" : "dec")
    }
    Battery {}
    Audio {}
    Audio { microphone: true }
    Chip { text: "|" }
    Connectivity {}
}
