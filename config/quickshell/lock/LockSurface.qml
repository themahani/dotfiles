import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../bar"
import "../services"
import "../theme"

WlSessionLockSurface {
    id: surface
    // The password field lives on the output that had focus; others show the clock.
    readonly property bool primary: !Hyprland.focusedMonitor || !screen || Hyprland.focusedMonitor.name === screen.name
    color: Theme.surface

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.wallpapers/.current"
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(surface.width / 2, surface.height / 2)   // it is blurred anyway
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: 0.1
        visible: wallpaper.status === Image.Ready
    }
    Rectangle { anchors.fill: parent; color: Theme.scrim; opacity: 0.38 }

    LockContent { anchors.fill: parent; primary: surface.primary }
    BarSurface { anchors.fill: parent; screen: surface.screen; locked: true }
}
