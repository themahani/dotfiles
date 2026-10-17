pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Which dropdown is open, and on which output. Only one is open at a time.
Singleton {
    id: root
    property string open: ""            // "", "system", "clock", "media" or "tray"
    property string screenName: ""
    property var trayItem: null         // SystemTrayItem whose menu is shown
    property string page: ""            // detail page to show when a panel opens

    function focusedScreenName() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens[0] || {}).name || "";
    }
    function toggle(name, screen) {
        const target = screen ? screen.name : focusedScreenName();
        if (open === name && screenName === target) close();
        else { screenName = target; open = name; }
    }
    function close() { open = ""; trayItem = null; }
    function isOpen(name, screen) { return open === name && screen && screenName === screen.name; }

    IpcHandler {
        target: "panels"
        function toggle(name: string): void { root.toggle(name, null); }
        // e.g. "openPage system wifi"; pages: wifi, bluetooth, output, input, power.
        function openPage(name: string, page: string): void {
            root.page = page;
            root.screenName = root.focusedScreenName();
            root.open = name;
        }
        function close(): void { root.close(); }
        function status(): string { return JSON.stringify({open: root.open, screen: root.screenName}); }
    }
}
