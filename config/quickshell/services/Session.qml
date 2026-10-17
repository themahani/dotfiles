pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The full-screen session menu (Super+X), which replaced wlogout. Each action
// keeps wlogout's key: l, r, s, e, u, h.
Singleton {
    id: root
    property bool open: false
    property string screenName: ""
    property bool canHibernate: false

    readonly property var allActions: [
        { id: "lock", key: "l", icon: "lock", label: "Lock", command: ["loginctl", "lock-session"] },
        { id: "reboot", key: "r", icon: "restart_alt", label: "Reboot", command: ["systemctl", "reboot"] },
        { id: "shutdown", key: "s", icon: "power_settings_new", label: "Shut down", command: ["systemctl", "poweroff"] },
        { id: "logout", key: "e", icon: "logout", label: "Log out", command: ["hyprshutdown"] },
        { id: "suspend", key: "u", icon: "bedtime", label: "Suspend", command: ["systemctl", "suspend"] },
        { id: "hibernate", key: "h", icon: "ac_unit", label: "Hibernate", command: ["systemctl", "hibernate"] }
    ]
    readonly property var actions: allActions.filter(action => action.id !== "hibernate" || canHibernate)

    function toggle() {
        if (open) { close(); return; }
        if (Lock.locked) return;        // the lock screen has its own power controls
        Panels.close();
        screenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens[0] || {}).name || "";
        open = true;
    }
    function close() { open = false; }
    function run(id) {
        const action = actions.find(entry => entry.id === id);
        if (!action) return;
        close();
        Quickshell.execDetached(action.command);
    }
    // Locking from elsewhere closes the menu, so it never shows over the lock.
    Connections {
        target: Lock
        function onLockedChanged() { if (Lock.locked) root.close(); }
    }

    // Hibernate needs swap that logind can resume from; hide it otherwise.
    Process {
        running: true
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "CanHibernate"]
        stdout: SplitParser { onRead: line => root.canHibernate = line.trim() === 's "yes"' }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { root.toggle(); }
        function close(): void { root.close(); }
        function status(): string {
            return JSON.stringify({open: root.open, screen: root.screenName, actions: root.actions.map(action => action.id)});
        }
    }
}
