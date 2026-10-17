pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray

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
    // Opens a panel on the focused output at a detail page, e.g. ("system", "wifi").
    function openPage(name, target) {
        page = target;
        screenName = focusedScreenName();
        open = name;
    }
    function isOpen(name, screen) { return open === name && screen && screenName === screen.name; }

    IpcHandler {
        target: "panels"
        function toggle(name: string): void { root.toggle(name, null); }
        // e.g. "openPage system wifi"; pages: wifi, bluetooth, output, input, power.
        function openPage(name: string, page: string): void { root.openPage(name, page); }
        // Opens the menu of the tray item whose id contains the text, e.g. "nm-applet".
        function tray(id: string): void {
            const item = SystemTray.items.values.find(entry => entry.id.toLowerCase().includes(id.toLowerCase()));
            if (!item || !item.hasMenu) return;
            root.trayItem = item;
            root.screenName = root.focusedScreenName();
            root.open = "tray";
        }
        function close(): void { root.close(); }
        function status(): string { return JSON.stringify({open: root.open, screen: root.screenName}); }
    }
}
