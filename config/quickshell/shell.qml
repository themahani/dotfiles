// Follow the GTK settings nwg-look writes (icon theme for tray and app icons).
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = gtk3
import Quickshell
import "services"
import "bar"
import "lock"
import "osd"

ShellRoot {
    // Instantiate shared services once, not once per output.
    property var notifications: Notifications
    property var controls: Controls
    property var metrics: Metrics
    property var panels: Panels

    Variants {
        model: Quickshell.screens
        Scope {
            id: output
            required property var modelData
            Reserver { screen: output.modelData }
            Drawer { screen: output.modelData }
        }
    }
    OsdWindow {}
    LockScreen {}
}
