import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../components"
import "../theme"

Row {
    id: root
    required property var screen
    property real maximumWidth: 300
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var toplevel: Hyprland.toplevels.values.find(window =>
        window.monitor === monitor && window.activated) || Hyprland.toplevels.values.find(window =>
        monitor && monitor.activeWorkspace && window.address === monitor.activeWorkspace.lastIpcObject.lastwindow)
        || (monitor && monitor.activeWorkspace ? monitor.activeWorkspace.toplevels.values[0] || null : null)
    readonly property string appId: toplevel ? (toplevel.wayland && toplevel.wayland.appId) || toplevel.lastIpcObject["class"] || "" : ""
    // Depend on the application list so the lookup reruns once it has loaded.
    readonly property var entry: appId && DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(appId) : null
    readonly property string iconSource: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : appId ? Quickshell.iconPath(appId, true) : ""
    visible: toplevel !== null
    spacing: 8
    IconImage {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconSource !== ""
        implicitSize: 18
        source: root.iconSource
        mipmap: true
    }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconSource === ""
        name: "web_asset"
        filled: true
        size: 18
        color: Theme.primary
    }
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.maximumWidth - 26)
        text: root.toplevel ? root.toplevel.title : ""
        opacity: root.toplevel && root.toplevel.activated ? 1 : 0.7
    }
}
