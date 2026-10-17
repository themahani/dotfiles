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
    // Pointer motion on any output starts the fingerprint scan; keys do it
    // in the password field. Qt repeats hover events for a still pointer
    // whenever the scene repaints, such as the text cursor blinking, so only
    // a new position counts.
    Item {
        anchors.fill: parent
        HoverHandler {
            property real lastX: -1
            property real lastY: -1
            onPointChanged: {
                const p = point.scenePosition;
                if (p.x === lastX && p.y === lastY) return;
                lastX = p.x;
                lastY = p.y;
                Lock.activity();
            }
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.wallpapers/.current"
        fillMode: Image.PreserveAspectCrop
        // No sourceSize: Qt's smooth downscale of the full image ran on a
        // thread pool and left about 45 MB allocated after unlocking, more
        // than decoding the wallpaper at full size costs.
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
