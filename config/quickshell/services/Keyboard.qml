pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The main keyboard's layout. Hyprland is asked once at startup and again
// on each activelayout or configreloaded event, instead of every second.
Singleton {
    id: root
    property string layout: ""          // e.g. "English (US)"
    property string name: ""            // the device name hyprctl switchxkblayout takes
    property bool pending: false

    function refresh() {
        if (devices.running) pending = true;
        else devices.running = true;
    }
    Process {
        id: devices
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const main = (JSON.parse(text).keyboards || []).find(keyboard => keyboard.main) || {};
                    root.layout = main.active_keymap || "";
                    root.name = main.name || "";
                } catch (error) { console.warn("Invalid hyprctl devices output:", error); }
            }
        }
        onExited: if (root.pending) { root.pending = false; running = true; }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout" || event.name === "configreloaded") root.refresh();
        }
    }
}
